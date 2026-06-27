part of 'eld_bloc.dart';

enum EldScanPhase { idle, scanning, completed }

sealed class EldState extends Equatable {
  const EldState({
    this.devices = const [],
    this.connectionState = EldConnectionState.disconnected,
    this.latestData,
    this.permissionsGranted = false,
    this.permissionStatuses = const [],
    this.permissionsLoading = false,
    this.scanPhase = EldScanPhase.idle,
    this.scanStartedAt,
    this.verifyingDeviceId,
  });

  final List<EldDevice> devices;
  final EldConnectionState connectionState;
  final EldData? latestData;
  final bool permissionsGranted;
  final List<PermissionStatusInfo> permissionStatuses;
  final bool permissionsLoading;
  final EldScanPhase scanPhase;
  final DateTime? scanStartedAt;
  final String? verifyingDeviceId;

  bool get isScanning => scanPhase == EldScanPhase.scanning;

  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
    EldScanPhase? scanPhase,
    DateTime? scanStartedAt,
    bool clearScanStartedAt = false,
    String? verifyingDeviceId,
    bool clearVerifyingDeviceId = false,
  });

  EldState copyWithLoading() => copyWith(permissionsLoading: true);

  @override
  List<Object?> get props => [
        devices,
        connectionState,
        latestData,
        permissionsGranted,
        permissionStatuses,
        permissionsLoading,
        scanPhase,
        scanStartedAt,
        verifyingDeviceId,
      ];
}

final class EldInitial extends EldState {
  const EldInitial({
    super.devices,
    super.connectionState,
    super.latestData,
    super.permissionsGranted,
    super.permissionStatuses,
    super.permissionsLoading,
    super.scanPhase,
    super.scanStartedAt,
    super.verifyingDeviceId,
  });

  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
    EldScanPhase? scanPhase,
    DateTime? scanStartedAt,
    bool clearScanStartedAt = false,
    String? verifyingDeviceId,
    bool clearVerifyingDeviceId = false,
  }) =>
      EldInitial(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        permissionStatuses: permissionStatuses ?? this.permissionStatuses,
        permissionsLoading: permissionsLoading ?? this.permissionsLoading,
        scanPhase: scanPhase ?? this.scanPhase,
        scanStartedAt:
            clearScanStartedAt ? null : (scanStartedAt ?? this.scanStartedAt),
        verifyingDeviceId: clearVerifyingDeviceId
            ? null
            : (verifyingDeviceId ?? this.verifyingDeviceId),
      );
}

final class EldScanning extends EldState {
  const EldScanning({
    super.devices,
    super.connectionState,
    super.latestData,
    super.permissionsGranted,
    super.permissionStatuses,
    super.permissionsLoading,
    super.scanPhase = EldScanPhase.scanning,
    super.scanStartedAt,
    super.verifyingDeviceId,
  });

  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
    EldScanPhase? scanPhase,
    DateTime? scanStartedAt,
    bool clearScanStartedAt = false,
    String? verifyingDeviceId,
    bool clearVerifyingDeviceId = false,
  }) =>
      EldScanning(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        permissionStatuses: permissionStatuses ?? this.permissionStatuses,
        permissionsLoading: permissionsLoading ?? this.permissionsLoading,
        scanPhase: scanPhase ?? this.scanPhase,
        scanStartedAt:
            clearScanStartedAt ? null : (scanStartedAt ?? this.scanStartedAt),
        verifyingDeviceId: clearVerifyingDeviceId
            ? null
            : (verifyingDeviceId ?? this.verifyingDeviceId),
      );
}

final class EldConnected extends EldState {
  const EldConnected({
    super.devices,
    super.connectionState = EldConnectionState.connected,
    super.latestData,
    super.permissionsGranted,
    super.permissionStatuses,
    super.permissionsLoading,
    super.scanPhase,
    super.scanStartedAt,
    super.verifyingDeviceId,
  });

  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
    EldScanPhase? scanPhase,
    DateTime? scanStartedAt,
    bool clearScanStartedAt = false,
    String? verifyingDeviceId,
    bool clearVerifyingDeviceId = false,
  }) =>
      EldConnected(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        permissionStatuses: permissionStatuses ?? this.permissionStatuses,
        permissionsLoading: permissionsLoading ?? this.permissionsLoading,
        scanPhase: scanPhase ?? this.scanPhase,
        scanStartedAt:
            clearScanStartedAt ? null : (scanStartedAt ?? this.scanStartedAt),
        verifyingDeviceId: clearVerifyingDeviceId
            ? null
            : (verifyingDeviceId ?? this.verifyingDeviceId),
      );
}

final class EldError extends EldState {
  const EldError(this.message, {this.previous});
  final String message;
  final EldState? previous;

  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
    EldScanPhase? scanPhase,
    DateTime? scanStartedAt,
    bool clearScanStartedAt = false,
    String? verifyingDeviceId,
    bool clearVerifyingDeviceId = false,
  }) =>
      previous?.copyWith(
        devices: devices,
        connectionState: connectionState,
        latestData: latestData,
        permissionsGranted: permissionsGranted,
        permissionStatuses: permissionStatuses,
        permissionsLoading: permissionsLoading,
        scanPhase: scanPhase,
        scanStartedAt: scanStartedAt,
        clearScanStartedAt: clearScanStartedAt,
        verifyingDeviceId: verifyingDeviceId,
        clearVerifyingDeviceId: clearVerifyingDeviceId,
      ) ??
      const EldInitial();

  @override
  List<Object?> get props => [message, previous];
}
