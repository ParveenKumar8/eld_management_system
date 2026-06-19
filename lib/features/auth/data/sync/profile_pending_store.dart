import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProfilePendingUpdate {
  const ProfilePendingUpdate({
    this.displayName,
    this.licenseNumber,
    required this.updatedAt,
  });

  final String? displayName;
  final String? licenseNumber;
  final DateTime updatedAt;

  bool get isEmpty => displayName == null && licenseNumber == null;
}

class ProfilePendingStore {
  static const _pendingKey = 'pending_profile_update';

  Future<Box<String>> _box() => Hive.openBox<String>(AppConstants.hiveBoxProfilePending);

  Future<void> save({
    String? displayName,
    String? licenseNumber,
  }) async {
    final box = await _box();
    final existing = await get();
    await box.put(
      _pendingKey,
      jsonEncode({
        'display_name': displayName ?? existing?.displayName,
        'license_number': licenseNumber ?? existing?.licenseNumber,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<ProfilePendingUpdate?> get() async {
    final box = await _box();
    final raw = box.get(_pendingKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final update = ProfilePendingUpdate(
      displayName: map['display_name'] as String?,
      licenseNumber: map['license_number'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
    return update.isEmpty ? null : update;
  }

  Future<void> clear() async {
    final box = await _box();
    await box.delete(_pendingKey);
  }
}