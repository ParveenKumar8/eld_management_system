import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';
import 'package:equatable/equatable.dart';

part 'eld_event.dart';
part 'eld_state.dart';

class EldBloc extends Bloc<EldEvent, EldState> {
  EldBloc(this._repository) : super(const EldInitial()) {
    on<EldPermissionsRequested>(_onPermissions);
    on<EldScanStarted>(_onScan);
    on<EldScanStopped>(_onStopScan);
    on<EldConnectRequested>(_onConnect);
    on<EldDisconnectRequested>(_onDisconnect);
    on<_EldDataReceived>(_onDataReceived);
    on<_EldConnectionChanged>(_onConnectionChanged);
    on<_EldDevicesUpdated>(_onDevicesUpdated);
    on<_EldErrorOccurred>(_onError);
  }

  final EldRepository _repository;
  StreamSubscription<List<EldDevice>>? _scanSub;
  StreamSubscription<EldData>? _dataSub;
  StreamSubscription<EldConnectionState>? _connSub;

  Future<void> _onPermissions(EldPermissionsRequested event, Emitter<EldState> emit) async {
    emit(state.copyWithLoading());
    final btResult = await _repository.isBluetoothAvailable();
    final unavailable = btResult.fold((_) => true, (available) => !available);
    if (unavailable) {
      emit(EldError('Bluetooth is unavailable', previous: state));
      return;
    }
    final perm = await _repository.requestPermissions();
    perm.fold(
      (f) => emit(EldError(f.message, previous: state)),
      (_) => emit(state.copyWith(permissionsGranted: true)),
    );
  }

  Future<void> _onScan(EldScanStarted event, Emitter<EldState> emit) async {
    await _scanSub?.cancel();
    emit(EldScanning(devices: state.devices, connectionState: EldConnectionState.scanning));

    _scanSub = _repository.scanDevices().listen(
      (devices) => add(_EldDevicesUpdated(devices)),
      onError: (Object e) => add(_EldErrorOccurred(e.toString())),
    );

    _connSub ??= _repository.watchConnectionState().listen(
      (s) => add(_EldConnectionChanged(s)),
    );
  }

  Future<void> _onStopScan(EldScanStopped event, Emitter<EldState> emit) async {
    await _scanSub?.cancel();
    emit(state.copyWith(connectionState: EldConnectionState.disconnected));
  }

  Future<void> _onConnect(EldConnectRequested event, Emitter<EldState> emit) async {
    emit(state.copyWith(connectionState: EldConnectionState.connecting));
    final result = await _repository.connect(event.deviceId);
    result.fold(
      (f) => emit(EldError(f.message, previous: state)),
      (_) {
        _dataSub?.cancel();
        _dataSub = _repository.watchEldData().listen(
          (d) => add(_EldDataReceived(d)),
        );
      },
    );
  }

  Future<void> _onDisconnect(EldDisconnectRequested event, Emitter<EldState> emit) async {
    await _dataSub?.cancel();
    await _repository.disconnect();
    emit(state.copyWith(connectionState: EldConnectionState.disconnected));
  }

  void _onDataReceived(_EldDataReceived event, Emitter<EldState> emit) {
    emit(state.copyWith(latestData: event.data, connectionState: EldConnectionState.connected));
  }

  void _onConnectionChanged(_EldConnectionChanged event, Emitter<EldState> emit) {
    emit(state.copyWith(connectionState: event.state));
  }

  void _onDevicesUpdated(_EldDevicesUpdated event, Emitter<EldState> emit) {
    emit(EldScanning(
      devices: event.devices,
      connectionState: state.connectionState,
      latestData: state.latestData,
      permissionsGranted: state.permissionsGranted,
    ));
  }

  void _onError(_EldErrorOccurred event, Emitter<EldState> emit) {
    emit(EldError(event.message, previous: state));
  }

  @override
  Future<void> close() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _connSub?.cancel();
    return super.close();
  }
}

// Private internal events
final class _EldDataReceived extends EldEvent {
  const _EldDataReceived(this.data);
  final EldData data;
}

final class _EldConnectionChanged extends EldEvent {
  const _EldConnectionChanged(this.state);
  final EldConnectionState state;
}

final class _EldDevicesUpdated extends EldEvent {
  const _EldDevicesUpdated(this.devices);
  final List<EldDevice> devices;
}

final class _EldErrorOccurred extends EldEvent {
  const _EldErrorOccurred(this.message);
  final String message;
}