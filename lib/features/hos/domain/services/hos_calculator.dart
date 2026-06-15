import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

/// FMCSA Hours of Service calculation engine (11-hour drive / 14-hour on-duty).
class HosCalculator {
  HosSummary calculateSummary({
    required List<HosRecord> records,
    required DateTime now,
  }) {
    final dayStart = DateTime.utc(now.year, now.month, now.day);
    final todayRecords = records.where((r) => r.startTime.isAfter(dayStart)).toList();

    var drivingMinutes = 0;
    var onDutyMinutes = 0;
    var offDutyMinutes = 0;

    for (final record in todayRecords) {
      final minutes = record.duration.inMinutes;
      switch (record.status) {
        case DutyStatus.driving:
          drivingMinutes += minutes;
          onDutyMinutes += minutes;
        case DutyStatus.onDutyNotDriving:
          onDutyMinutes += minutes;
        case DutyStatus.offDuty:
        case DutyStatus.sleeperBerth:
          offDutyMinutes += minutes;
      }
    }

    final remainingDrive =
        (AppConstants.maxDrivingMinutesPerDay - drivingMinutes).clamp(0, 999);
    final remainingOnDuty =
        (AppConstants.maxOnDutyMinutesPerDay - onDutyMinutes).clamp(0, 999);

    final weekDriving = _weekDrivingMinutes(records, now);
    final remainingCycle =
        (AppConstants.maxDrivingMinutesPerWeek - weekDriving).clamp(0, 999);

    String? violation;
    var inViolation = false;
    if (drivingMinutes > AppConstants.maxDrivingMinutesPerDay) {
      inViolation = true;
      violation = 'Exceeded 11-hour driving limit';
    } else if (onDutyMinutes > AppConstants.maxOnDutyMinutesPerDay) {
      inViolation = true;
      violation = 'Exceeded 14-hour on-duty window';
    } else if (weekDriving > AppConstants.maxDrivingMinutesPerWeek) {
      inViolation = true;
      violation = 'Exceeded 60-hour/7-day cycle';
    }

    return HosSummary(
      remainingDriveMinutes: remainingDrive,
      remainingOnDutyMinutes: remainingOnDuty,
      remainingCycleMinutes: remainingCycle,
      drivingMinutesToday: drivingMinutes,
      onDutyMinutesToday: onDutyMinutes,
      offDutyMinutesSinceLastReset: offDutyMinutes,
      isInViolation: inViolation,
      violationMessage: violation,
    );
  }

  int _weekDrivingMinutes(List<HosRecord> records, DateTime now) {
    final weekStart = now.subtract(const Duration(days: 7));
    return records
        .where(
          (r) =>
              r.status == DutyStatus.driving &&
              r.startTime.isAfter(weekStart),
        )
        .fold<int>(0, (sum, r) => sum + r.duration.inMinutes);
  }

  /// Auto-suggest duty status from ELD movement data.
  DutyStatus suggestStatusFromEld({required bool isMoving, required double speedMph}) {
    if (isMoving || speedMph > 5) {
      return DutyStatus.driving;
    }
    return DutyStatus.onDutyNotDriving;
  }
}