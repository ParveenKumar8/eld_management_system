part of 'eld_bloc.dart';

sealed class EldState extends Equatable {
  const EldState({
    this.devices = const [],
    this.connectionState = EldConnectionState.disconnected,
    this.latestData,
    this.permissionsGranted = false,
  });

  final List<EldDevice> devices;
  final EldConnectionState connectionState;
  final EldData? latestData;
  final bool permissionsGranted;

  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
  });

  EldState copyWithLoading() => copyWith();

  @override
  List<Object?> get props => [devices, connectionState, latestData, permissionsGranted];
}

final class EldInitial extends EldState {
  const EldInitial();
  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
  }) =>
      EldInitial();
}

final class EldScanning extends EldState {
  const EldScanning({
    super.devices,
    super.connectionState,
    super.latestData,
    super.permissionsGranted,
  });
  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
  }) =>
      EldScanning(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      );
}

final class EldConnected extends EldState {
  const EldConnected({
    super.devices,
    super.connectionState = EldConnectionState.connected,
    super.latestData,
    super.permissionsGranted,
  });
  @override
  EldState copyWith({
    List<EldDevice>? devices,
    EldConnectionState? connectionState,
    EldData? latestData,
    bool? permissionsGranted,
  }) =>
      EldConnected(
        devices: devices ?? this.devices,
        connectionState: connectionState ?? this.connectionState,
        latestData: latestData ?? this.latestData,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
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
  }) =>
      previous?.copyWith(
            devices: devices,
            connectionState: connectionState,
            latestData: latestData,
            permissionsGranted: permissionsGranted,
          ) ??
      const EldInitial();

  @override
  List<Object?> get props => [message, previous];
}