import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/strings/ble_strings.dart';
import 'package:eld_management_system/core/strings/permission_strings.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';
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
    on<_EldScanCompleted>(_onScanCompleted);
  }

  final EldRepository _repository;
  StreamSubscription<List<EldDevice>>? _scanSub;
  StreamSubscription<EldData>? _dataSub;
  StreamSubscription<EldConnectionState>? _connSub;

  Future<void> _onPermissions(
      EldPermissionsRequested event, Emitter<EldState> emit) async {
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
      (f) => emit(EldError(f.message,
          previous: state.copyWith(permissionsLoading: false))),
      (grant) => emit(
        state.copyWith(
          permissionStatuses: grant.statuses,
          permissionsGranted: grant.allRequiredGranted,
          permissionsLoading: false,
        ),
      ),
    );
  }

  Future<void> _onOpenSettings(
      EldOpenSettingsRequested event, Emitter<EldState> emit) async {
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
    final startedAt = DateTime.now();

    emit(
      baseline.copyWith(
        devices: const [],
        connectionState: EldConnectionState.scanning,
        scanPhase: EldScanPhase.scanning,
        scanStartedAt: startedAt,
      ),
    );

    if (!_permissionsReady(_viewState(state))) {
      await _runPermissionFlow(emit);
    }

    final ready = _viewState(state);
    if (!_permissionsReady(ready)) {
      final reverted = ready.copyWith(
        connectionState: EldConnectionState.disconnected,
        scanPhase: EldScanPhase.idle,
        clearScanStartedAt: true,
      );
      final hadError = state is EldError;
      emit(reverted);
      if (!hadError) {
        emit(EldError(PermissionStrings.deniedSummaryPrefix, previous: reverted));
      }
      return;
    }

    await _scanSub?.cancel();
    emit(
      EldScanning(
        devices: const [],
        connectionState: EldConnectionState.scanning,
        permissionsGranted: _permissionsReady(ready),
        permissionStatuses: ready.permissionStatuses,
        scanPhase: EldScanPhase.scanning,
        scanStartedAt: startedAt,
      ),
    );

    _scanSub = _repository.scanDevices(timeout: AppConstants.bleScanTimeout).listen(
          (devices) => add(_EldDevicesUpdated(devices)),
          onError: (Object e) => add(_EldErrorOccurred(e.toString())),
          onDone: () => add(const _EldScanCompleted()),
        );

    _connSub ??= _repository.watchConnectionState().listen(
          (s) => add(_EldConnectionChanged(s)),
        );
  }

  Future<void> _onStopScan(EldScanStopped event, Emitter<EldState> emit) async {
    await _scanSub?.cancel();
    await _repository.stopScan();
    emit(
      state.copyWith(
        connectionState: EldConnectionState.disconnected,
        scanPhase: EldScanPhase.idle,
        clearScanStartedAt: true,
      ),
    );
  }

  void _onScanCompleted(_EldScanCompleted event, Emitter<EldState> emit) {
    emit(
      EldScanning(
        devices: state.devices,
        connectionState: EldConnectionState.disconnected,
        latestData: state.latestData,
        permissionsGranted: state.permissionsGranted,
        permissionStatuses: state.permissionStatuses,
        permissionsLoading: state.permissionsLoading,
        scanPhase: EldScanPhase.completed,
        verifyingDeviceId: state.verifyingDeviceId,
      ),
    );
  }

  Future<void> _onConnect(
      EldConnectRequested event, Emitter<EldState> emit) async {
    final baseline = _viewState(state);
    emit(
      baseline.copyWith(
        connectionState: EldConnectionState.verifying,
        verifyingDeviceId: event.deviceId,
      ),
    );

    final result = await _repository.connect(event.deviceId);
    result.fold(
      (f) {
        final compatibility = f.code == 'eld_incompatible'
            ? EldDeviceCompatibility.incompatible
            : null;
        final devices = compatibility == null
            ? baseline.devices
            : _updateDeviceCompatibility(baseline.devices, event.deviceId, compatibility);
        emit(
          EldError(
            f.message,
            previous: baseline.copyWith(
              devices: devices,
              connectionState: EldConnectionState.disconnected,
              clearVerifyingDeviceId: true,
            ),
          ),
        );
      },
      (_) {
        final devices = _updateDeviceCompatibility(
          baseline.devices,
          event.deviceId,
          EldDeviceCompatibility.compatible,
        );
        emit(
          baseline.copyWith(
            devices: devices,
            connectionState: EldConnectionState.connected,
            clearVerifyingDeviceId: true,
          ),
        );
        _dataSub?.cancel();
        _dataSub = _repository.watchEldData().listen(
              (d) => add(_EldDataReceived(d)),
            );
      },
    );
  }

  Future<void> _onDisconnect(
      EldDisconnectRequested event, Emitter<EldState> emit) async {
    await _dataSub?.cancel();
    await _repository.disconnect();
    emit(state.copyWith(connectionState: EldConnectionState.disconnected));
  }

  void _onDataReceived(_EldDataReceived event, Emitter<EldState> emit) {
    emit(state.copyWith(
        latestData: event.data, connectionState: EldConnectionState.connected));
  }

  void _onConnectionChanged(
      _EldConnectionChanged event, Emitter<EldState> emit) {
    emit(state.copyWith(connectionState: event.state));
  }

  void _onDevicesUpdated(_EldDevicesUpdated event, Emitter<EldState> emit) {
    emit(
      EldScanning(
        devices: event.devices,
        connectionState: state.connectionState,
        latestData: state.latestData,
        permissionsGranted: state.permissionsGranted,
        permissionStatuses: state.permissionStatuses,
        permissionsLoading: state.permissionsLoading,
        scanPhase: EldScanPhase.scanning,
        scanStartedAt: state.scanStartedAt,
      ),
    );
  }

  void _onError(_EldErrorOccurred event, Emitter<EldState> emit) {
    emit(
      EldError(
        event.message,
        previous: state.copyWith(
          connectionState: EldConnectionState.disconnected,
          scanPhase: EldScanPhase.completed,
          clearScanStartedAt: true,
        ),
      ),
    );
  }

  bool _requiredGranted(List<PermissionStatusInfo> items) =>
      items.isNotEmpty && items.where((s) => s.required).every((s) => s.isGranted);

  bool _permissionsReady(EldState state) =>
      state.permissionsGranted || _requiredGranted(state.permissionStatuses);

  EldState _viewState(EldState current) =>
      current is EldError ? (current.previous ?? current) : current;

  List<EldDevice> _updateDeviceCompatibility(
    List<EldDevice> devices,
    String deviceId,
    EldDeviceCompatibility compatibility,
  ) =>
      devices
          .map(
            (device) => device.id == deviceId
                ? device.copyWith(compatibility: compatibility)
                : device,
          )
          .toList();

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

final class _EldScanCompleted extends EldEvent {
  const _EldScanCompleted();
}
