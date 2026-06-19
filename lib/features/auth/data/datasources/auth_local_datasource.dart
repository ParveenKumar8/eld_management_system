import 'package:eld_management_system/core/security/secure_storage_service.dart';
import 'package:eld_management_system/features/auth/data/models/user_model.dart';
import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._secureStorage);
  final SecureStorageService _secureStorage;
  static const String _userKey = 'cached_user';

  Future<void> cacheSession({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final box = await Hive.openBox<String>('auth');
    await box.put(_userKey, user.email);
    await box.put('${_userKey}_id', user.id);
    await box.put('${_userKey}_role', user.role.value);
    await box.put('${_userKey}_name', user.displayName);
    if (user.licenseNumber != null) {
      await box.put('${_userKey}_license', user.licenseNumber!);
    }
    if (user.carrierId != null) {
      await box.put('${_userKey}_carrier', user.carrierId!);
    }
  }

  Future<UserModel?> getCachedUser() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null) return null;
    final box = await Hive.openBox<String>('auth');
    final email = box.get(_userKey);
    if (email == null) return null;
    return UserModel(
      id: box.get('${_userKey}_id') ?? 'cached-${email.hashCode}',
      email: email,
      displayName: box.get('${_userKey}_name') ?? email,
      role: UserRole.fromString(box.get('${_userKey}_role') ?? 'driver'),
      licenseNumber: box.get('${_userKey}_license'),
      carrierId: box.get('${_userKey}_carrier'),
    );
  }

  Future<String?> getRefreshToken() => _secureStorage.getRefreshToken();

  Future<String?> getAccessToken() => _secureStorage.getAccessToken();

  Future<void> updateCachedUser(UserModel user) async {
    final access = await _secureStorage.getAccessToken();
    final refresh = await _secureStorage.getRefreshToken();
    if (access == null || refresh == null) return;
    await cacheSession(user: user, accessToken: access, refreshToken: refresh);
  }

  Future<void> clearSession() async {
    await _secureStorage.clearTokens();
    final box = await Hive.openBox<String>('auth');
    await box.clear();
  }
}