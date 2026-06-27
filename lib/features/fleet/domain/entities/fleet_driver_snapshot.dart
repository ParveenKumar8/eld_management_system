import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:equatable/equatable.dart';

class FleetDriverSnapshot extends Equatable {
  const FleetDriverSnapshot({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.licenseNumber,
    this.carrierId,
    this.currentStatus,
    required this.isInViolation,
    this.violationMessage,
    required this.remainingDriveMinutes,
    required this.uncertifiedCount,
    required this.editedCount,
    required this.hasPushToken,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? licenseNumber;
  final String? carrierId;
  final DutyStatus? currentStatus;
  final bool isInViolation;
  final String? violationMessage;
  final int remainingDriveMinutes;
  final int uncertifiedCount;
  final int editedCount;
  final bool hasPushToken;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        role,
        licenseNumber,
        carrierId,
        currentStatus,
        isInViolation,
        violationMessage,
        remainingDriveMinutes,
        uncertifiedCount,
        editedCount,
        hasPushToken,
      ];
}