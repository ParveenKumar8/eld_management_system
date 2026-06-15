part of 'eld_bloc.dart';

sealed class EldState extends Equatable {
  const EldState({
    this.devices = const [],
    this.connectionState = EldConnectionState.disconnected,
    this.latestData,
    this.permissionsGranted = false,
    this.permissionStatuses = const [],
    this.permissionsLoading = false,
  });

  final List<EldDevice> devices;
  final EldConnectionState connectionState;
  final EldData? latestData;
  final bool permissionsGranted;
  final List<PermissionStatusInfo> permissionStatuses;
  final bool permissionsLoading;

  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
  });

  EldState copyWithLoading() => copyWith(permissionsLoading: true);

  @override
  List<Object?> get props =>
      [devices, connectionState, latestData, permissionsGranted, permissionStatuses, permissionsLoading];
}

final class EldInitial extends EldState {
  const EldInitial();
  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
  }) =>
      EldInitial();
}

final class EldScanning extends EldState {
  const EldScanning({
    super.devices,
    super.connectionState,
    super.latestData,
    super.permissionsGranted,
    super.permissionStatuses,
    super.permissionsLoading,
  });
  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
  }) =>
      EldScanning(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        permissionStatuses: permissionStatuses ?? this.permissionStatuses,
        permissionsLoading: permissionsLoading ?? this.permissionsLoading,
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
  });
  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
    List<PermissionStatusInfo>? permissionStatuses,
    bool? permissionsLoading,
  }) =>
      EldConnected(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        permissionStatuses: permissionStatuses ?? this.permissionStatuses,
        permissionsLoading: permissionsLoading ?? this.permissionsLoading,
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
  }) =>
      previous?.copyWith(
            devices: devices,
            connectionState: connectionState,
            latestData: latestData,
            permissionsGranted: permissionsGranted,
            permissionStatuses: permissionStatuses,
            permissionsLoading: permissionsLoading,
          ) ??
      const EldInitial();

  @override
  List<Object?> get props => [message, previous];
}