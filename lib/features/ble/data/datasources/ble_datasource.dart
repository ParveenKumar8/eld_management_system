import 'dart:async';
import 'dart:io';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/features/ble/data/parsers/geometris_parser.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/core/strings/ble_strings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE data source using flutter_blue_plus with auto-reconnect.
class BleDataSource {
  BleDataSource({required GeometrisParser parser}) : _parser = parser;

  final GeometrisParser _parser;
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
    await FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: [Guid(AppConstants.geometrisServiceUuid)],
    );

    final devices = <String, EldDevice>{};
    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        if (name.isEmpty) continue;
        if (!name.toUpperCase().contains('WHERE') &&
            !name.toUpperCase().contains('GEOMETRIS') &&
            !name.toUpperCase().contains('ELD')) {
          continue;
        }
        devices[r.device.remoteId.str] = EldDevice(
          id: r.device.remoteId.str,
          name: name,
          rssi: r.rssi,
        );
      }
      yield devices.values.toList();
    }
    await FlutterBluePlus.stopScan();
    if (_connectedDevice == null) {
      _connectionController.add(EldConnectionState.disconnected);
    }
  }

  Future<void> connect(String deviceId) async {
    _connectionController.add(EldConnectionState.connecting);
    _lastDeviceId = deviceId;
    _reconnectAttempts = 0;

    await FlutterBluePlus.stopScan();
    final device = BluetoothDevice.fromId(deviceId);
    _connectedDevice = device;

    await device.connect(
      autoConnect: true,
      mtu: null,
      timeout: const Duration(seconds: 20),
    );

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

    await _subscribeToNotifications(device);
    _connectionController.add(EldConnectionState.connected);
    AppLogger.info('Connected to ELD: $deviceId');
  }

  Future<void> _subscribeToNotifications(BluetoothDevice device) async {
    final services = await device.discoverServices();
    BluetoothCharacteristic? notifyChar;

    for (final service in services) {
      if (service.uuid.str.toLowerCase().contains('fff0') ||
          service.uuid == Guid(AppConstants.geometrisServiceUuid)) {
        for (final c in service.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            notifyChar = c;
            break;
          }
        }
      }
    }

    notifyChar ??= _findFirstNotifiable(services);
    if (notifyChar == null) {
      throw BleException(BleStrings.noNotifiableCharacteristic);
    }

    await notifyChar.setNotifyValue(true);
    _notifySubscription?.cancel();
    _notifySubscription = notifyChar.lastValueStream.listen(_onRawData);
  }

  BluetoothCharacteristic? _findFirstNotifiable(List<BluetoothService> services) {
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.notify) return c;
      }
    }
    return null;
  }

  void _onRawData(List<int> bytes) {
    final parsed = _parser.parse(bytes);
    if (parsed == null) return;
    _buffer.add(parsed);
    if (_buffer.length > 5000) {
      _buffer.removeRange(0, _buffer.length - 5000);
    }
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