import 'package:equatable/equatable.dart';

/// Remaining HOS availability per FMCSA rules.
class HosSummary extends Equatable {
  const HosSummary({
    required this.remainingDriveMinutes,
    required this.remainingOnDutyMinutes,
    required this.remainingCycleMinutes,
    required this.drivingMinutesToday,
    required this.onDutyMinutesToday,
    required this.offDutyMinutesSinceLastReset,
    required this.isInViolation,
    this.violationMessage,
  });

  final int remainingDriveMinutes;
  final int remainingOnDutyMinutes;
  final int remainingCycleMinutes;
  final int drivingMinutesToday;
  final int onDutyMinutesToday;
  final int offDutyMinutesSinceLastReset;
  final bool isInViolation;
  final String? violationMessage;

  @override
  List<Object?> get props => [
        remainingDriveMinutes,
        remainingOnDutyMinutes,
        remainingCycleMinutes,
        drivingMinutesToday,
        onDutyMinutesToday,
        offDutyMinutesSinceLastReset,
        isInViolation,
        violationMessage,
      ];
}