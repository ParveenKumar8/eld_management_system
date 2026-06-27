import 'package:equatable/equatable.dart';

class FleetPushResult extends Equatable {
  const FleetPushResult({
    required this.targetedDrivers,
    required this.deviceTokens,
    required this.sent,
    required this.failed,
    required this.skipped,
    required this.mode,
  });

  final int targetedDrivers;
  final int deviceTokens;
  final int sent;
  final int failed;
  final int skipped;
  final String mode;

  @override
  List<Object?> get props => [
        targetedDrivers,
        deviceTokens,
        sent,
        failed,
        skipped,
        mode,
      ];
}