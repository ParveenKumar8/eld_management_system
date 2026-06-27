import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_driver_snapshot.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_overview.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_push_result.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

abstract final class FleetMapper {
  static FleetOverview overviewFromJson(Map<String, dynamic> json) => FleetOverview(
        driverCount: json['driver_count'] as int? ?? 0,
        violationCount: json['violation_count'] as int? ?? 0,
        uncertifiedDriverCount: json['uncertified_driver_count'] as int? ?? 0,
        editedDriverCount: json['edited_driver_count'] as int? ?? 0,
        registeredPushTokens: json['registered_push_tokens'] as int? ?? 0,
      );

  static FleetDriverSnapshot driverFromJson(Map<String, dynamic> json) {
    final statusCode = json['current_status'] as String?;
    return FleetDriverSnapshot(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'driver'),
      licenseNumber: json['license_number'] as String?,
      carrierId: json['carrier_id'] as String?,
      currentStatus: statusCode != null ? DutyStatus.fromCode(statusCode) : null,
      isInViolation: json['is_in_violation'] as bool? ?? false,
      violationMessage: json['violation_message'] as String?,
      remainingDriveMinutes: json['remaining_drive_minutes'] as int? ?? 0,
      uncertifiedCount: json['uncertified_count'] as int? ?? 0,
      editedCount: json['edited_count'] as int? ?? 0,
      hasPushToken: json['has_push_token'] as bool? ?? false,
    );
  }

  static HosSummary summaryFromJson(Map<String, dynamic> json) => HosSummary(
        remainingDriveMinutes: json['remaining_drive_minutes'] as int? ?? 0,
        remainingOnDutyMinutes: json['remaining_on_duty_minutes'] as int? ?? 0,
        remainingCycleMinutes: json['remaining_cycle_minutes'] as int? ?? 0,
        drivingMinutesToday: json['driving_minutes_today'] as int? ?? 0,
        onDutyMinutesToday: json['on_duty_minutes_today'] as int? ?? 0,
        offDutyMinutesSinceLastReset:
            json['off_duty_minutes_since_last_reset'] as int? ?? 0,
        isInViolation: json['is_in_violation'] as bool? ?? false,
        violationMessage: json['violation_message'] as String?,
      );

  static FleetPushResult pushResultFromJson(Map<String, dynamic> json) =>
      FleetPushResult(
        targetedDrivers: json['targeted_drivers'] as int? ?? 0,
        deviceTokens: json['device_tokens'] as int? ?? 0,
        sent: json['sent'] as int? ?? 0,
        failed: json['failed'] as int? ?? 0,
        skipped: json['skipped'] as int? ?? 0,
        mode: json['mode'] as String? ?? 'unknown',
      );
}