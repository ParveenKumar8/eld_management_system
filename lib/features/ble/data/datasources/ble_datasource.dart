import 'dart:async';
import 'dart:io';

import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/strings/ble_strings.dart';
import 'package:eld_management_system/features/ble/data/parsers/geometris_parser.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_telemetry_buffer.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';
import 'package:eld_management_system/features/ble/domain/services/eld_compatibility.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE data source using flutter_blue_plus with auto-reconnect.
class BleDataSource {
  BleDataSource({
    required GeometrisParser parser,
    EldTelemetryBuffer? telemetryBuffer,
  }) : _parser = parser,
       _telemetryBuffer = telemetryBuffer;

  final GeometrisParser _parser;
  final EldTelemetryBuffer? _telemetryBuffer;
  final _connectionController = StreamController<EldConnectionState>.broadcast();
  final _dataController = StreamController<EldData>.broadcast();
  final List<EldData> _buffer = [];

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  Timer? _reconnectTimer;
  String? _lastDeviceId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  Stream<EldConnectionState> get connectionState => _connectionController.stream;
  Stream<EldData> get eldDataStream => _dataController.stream;
  List<EldData> get buffer => List.unmodifiable(_buffer);
  String? get connectedDeviceId => _lastDeviceId;

  void clearBuffer() => _buffer.clear();

  Future<bool> isBluetoothAvailable() async {
    try {
      if (Platform.isAndroid) {
        final state = await FlutterBluePlus.adapterState.first;
        return state == BluetoothAdapterState.on;
      }
      return FlutterBluePlus.isSupported;
    } catch (e) {
      AppLogger.error('Bluetooth availability check', e);
      return false;
    }
  }

  Stream<List<EldDevice>> scan({Duration timeout = const Duration(seconds: 15)}) async* {
    _connectionController.add(EldConnectionState.scanning);
    await FlutterBluePlus.startScan(timeout: timeout);

    final devices = <String, EldDevice>{};
    await for (final results in FlutterBluePlus.scanResults) {
      for (final result in results) {
        final device = _mapScanResult(result);
        devices[device.id] = device;
      }
      yield _sortedDevices(devices.values);
    }
    await FlutterBluePlus.stopScan();
    if (_connectedDevice == null) {
      _connectionController.add(EldConnectionState.disconnected);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_connectedDevice == null) {
      _connectionController.add(EldConnectionState.disconnected);
    }
  }

  Future<void> connect(String deviceId) async {
    _connectionController.add(EldConnectionState.verifying);
    _lastDeviceId = deviceId;
    _reconnectAttempts = 0;

    await FlutterBluePlus.stopScan();
    final device = BluetoothDevice.fromId(deviceId);
    _connectedDevice = device;

    try {
      await device.connect(
        autoConnect: false,
        mtu: null,
        timeout: const Duration(seconds: 20),
      );

      final services = await device.discoverServices();
      if (!EldCompatibility.hasEldServices(services)) {
        await device.disconnect();
        _connectedDevice = null;
        _connectionController.add(EldConnectionState.disconnected);
        throw const IncompatibleEldException(message: BleStrings.deviceNotEldCompatible);
      }

      _stateSubscription?.cancel();
      _stateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionController.add(EldConnectionState.reconnecting);
          _scheduleReconnect();
        } else if (state == BluetoothConnectionState.connected) {
          _connectionController.add(EldConnectionState.connected);
          _reconnectAttempts = 0;
        }
      });

      await _subscribeToNotifications(device, services);
      _connectionController.add(EldConnectionState.connected);
      AppLogger.info('Connected to ELD: $deviceId');
    } catch (e) {
      if (e is! IncompatibleEldException) {
        _connectedDevice = null;
        _connectionController.add(EldConnectionState.disconnected);
      }
      rethrow;
    }
  }

  EldDevice _mapScanResult(ScanResult result) {
    final name = _displayName(result);
    return EldDevice(
      id: result.device.remoteId.str,
      name: name,
      rssi: result.rssi,
      compatibility: EldCompatibility.hintFromAdvertisement(
        name: name,
        serviceUuids: result.advertisementData.serviceUuids,
      ),
    );
  }

  String _displayName(ScanResult result) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;
    if (name.isNotEmpty) return name;
    final id = result.device.remoteId.str;
    final suffix = id.length > 8 ? id.substring(id.length - 8) : id;
    return 'Bluetooth device • $suffix';
  }

  List<EldDevice> _sortedDevices(Iterable<EldDevice> devices) {
    final list = devices.toList()
      ..sort((a, b) {
        final hintCompare = _compatibilityRank(b.compatibility)
            .compareTo(_compatibilityRank(a.compatibility));
        if (hintCompare != 0) return hintCompare;
        return b.rssi.compareTo(a.rssi);
      });
    return list;
  }

  int _compatibilityRank(EldDeviceCompatibility compatibility) => switch (compatibility) {
        EldDeviceCompatibility.compatible => 3,
        EldDeviceCompatibility.likely => 2,
        EldDeviceCompatibility.unknown => 1,
        EldDeviceCompatibility.incompatible => 0,
      };

  Future<void> _subscribeToNotifications(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    final notifyChar = EldCompatibility.findEldNotifyCharacteristic(services);
    if (notifyChar == null) {
      throw const BleException(BleStrings.noNotifiableCharacteristic);
    }

    await notifyChar.setNotifyValue(true);
    _notifySubscription?.cancel();
    _notifySubscription = notifyChar.lastValueStream.listen(_onRawData);
  }

  void _onRawData(List<int> bytes) {
    final parsed = _parser.parse(bytes);
    if (parsed == null) return;
    _buffer.add(parsed);
    if (_buffer.length > 5000) {
      _buffer.removeRange(0, _buffer.length - 5000);
    }
    final deviceId = _lastDeviceId ?? 'unknown';
    unawaited(
      _telemetryBuffer?.append(data: parsed, deviceId: deviceId),
    );
    _dataController.add(parsed);
  }

  void _scheduleReconnect() {
    if (_lastDeviceId == null || _reconnectAttempts >= _maxReconnectAttempts) {
      _connectionController.add(EldConnectionState.error);
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 2 * (_reconnectAttempts + 1)), () async {
      _reconnectAttempts++;
      try {
        await connect(_lastDeviceId!);
      } catch (e) {
        AppLogger.warning('Reconnect attempt $_reconnectAttempts failed', e);
        _scheduleReconnect();
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _notifySubscription?.cancel();
    _stateSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _connectionController.add(EldConnectionState.disconnected);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _notifySubscription?.cancel();
    _stateSubscription?.cancel();
    _connectionController.close();
    _dataController.close();
  }
}