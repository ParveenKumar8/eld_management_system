part of 'eld_bloc.dart';

sealed class EldEvent extends Equatable {
  const EldEvent();
  @override
  List<Object?> get props => [];
}

final class EldPermissionsRequested extends EldEvent {
  const EldPermissionsRequested();
}

final class EldScanStarted extends EldEvent {
  const EldScanStarted();
}

final class EldScanStopped extends EldEvent {
  const EldScanStopped();
}

final class EldConnectRequested extends EldEvent {
  const EldConnectRequested(this.deviceId);
  final String deviceId;
  @override
  List<Object?> get props => [deviceId];
}

final class EldDisconnectRequested extends EldEvent {
  const EldDisconnectRequested();
}