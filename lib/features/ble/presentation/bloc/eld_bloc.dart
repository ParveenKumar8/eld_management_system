import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/strings/ble_strings.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';
import 'package:equatable/equatable.dart';

part 'eld_event.dart';
part 'eld_state.dart';

class EldBloc extends Bloc<EldEvent, EldState> {
  EldBloc(this._repository) : super(const EldInitial()) {
    on<EldPermissionsRequested>(_onPermissions);
    on<EldPermissionsRefreshRequested>(_onRefreshPermissions);
    on<EldPermissionItemRequested>(_onPermissionItem);
    on<EldOpenSettingsRequested>(_onOpenSettings);
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
    await _runPermissionFlow(emit);
  }

  Future<void> _onRefreshPermissions(
    EldPermissionsRefreshRequested event,
    Emitter<EldState> emit,
  ) async {
    emit(state.copyWith(permissionsLoading: true));
    final statuses = await _repository.getPermissionStatuses();
    statuses.fold(
      (f) => emit(EldError(f.message, previous: state)),
      (items) => emit(
        state.copyWith(
          permissionStatuses: items,
          permissionsGranted: _requiredGranted(items),
          permissionsLoading: false,
        ),
      ),
    );
  }

  Future<void> _onPermissionItem(
    EldPermissionItemRequested event,
    Emitter<EldState> emit,
  ) async {
    emit(state.copyWith(permissionsLoading: true));
    final result = await _repository.requestPermissions(kind: event.kind);
    result.fold(
      (f) => emit(EldError(f.message, previous: state.copyWith(permissionsLoading: false))),
      (grant) => emit(
        state.copyWith(
          permissionStatuses: grant.statuses,
          permissionsGranted: grant.allRequiredGranted,
          permissionsLoading: false,
        ),
      ),
    );
  }

  Future<void> _onOpenSettings(EldOpenSettingsRequested event, Emitter<EldState> emit) async {
    await _repository.openPermissionSettings();
    add(const EldPermissionsRefreshRequested());
  }

  Future<void> _runPermissionFlow(Emitter<EldState> emit) async {
    emit(state.copyWith(permissionsLoading: true));

    final btResult = await _repository.isBluetoothAvailable();
    final unavailable = btResult.fold((_) => true, (available) => !available);
    if (unavailable) {
      emit(
        EldError(
          BleStrings.bluetoothUnavailable,
          previous: state.copyWith(permissionsLoading: false),
        ),
      );
      return;
    }

    final refresh = await _repository.getPermissionStatuses();
    await refresh.fold(
      (f) async => emit(EldError(f.message, previous: state)),
      (statuses) async {
        emit(state.copyWith(permissionStatuses: statuses));
        final grant = await _repository.requestPermissions();
        grant.fold(
          (f) => emit(
            EldError(
              f.message,
              previous: state.copyWith(
                permissionStatuses: statuses,
                permissionsGranted: false,
                permissionsLoading: false,
              ),
            ),
          ),
          (result) => emit(
            state.copyWith(
              permissionStatuses: result.statuses,
              permissionsGranted: result.allRequiredGranted,
              permissionsLoading: false,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onScan(EldScanStarted event, Emitter<EldState> emit) async {
    final baseline = _viewState(state);
    if (!baseline.permissionsGranted) {
      await _runPermissionFlow(emit);
    }

    final ready = _viewState(state);
    if (!ready.permissionsGranted) return;

    await _scanSub?.cancel();
    emit(EldScanning(
      devices: ready.devices,
      connectionState: EldConnectionState.scanning,
      permissionsGranted: ready.permissionsGranted,
      permissionStatuses: ready.permissionStatuses,
    ));

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
      permissionStatuses: state.permissionStatuses,
      permissionsLoading: state.permissionsLoading,
    ));
  }

  void _onError(_EldErrorOccurred event, Emitter<EldState> emit) {
    emit(EldError(event.message, previous: state));
  }

  bool _requiredGranted(List<PermissionStatusInfo> items) =>
      items.where((s) => s.required).every((s) => s.isGranted);

  EldState _viewState(EldState current) =>
      current is EldError ? (current.previous ?? current) : current;

  @override
  Future<void> close() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _connSub?.cancel();
    return super.close();
  }
}

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