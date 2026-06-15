import 'package:equatable/equatable.dart';
import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.licenseNumber,
    this.carrierId,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? licenseNumber;
  final String? carrierId;

  @override
  List<Object?> get props => [id, email, displayName, role, licenseNumber, carrierId];
}