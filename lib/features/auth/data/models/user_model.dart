import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.role,
    super.licenseNumber,
    super.carrierId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? json['email'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'driver'),
      licenseNumber: json['license_number'] as String?,
      carrierId: json['carrier_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'role': role.value,
        'license_number': licenseNumber,
        'carrier_id': carrierId,
      };

  User toEntity() => User(
        id: id,
        email: email,
        displayName: displayName,
        role: role,
        licenseNumber: licenseNumber,
        carrierId: carrierId,
      );
}