import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for tokens and sensitive FMCSA data.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  factory SecureStorageService.create() => const SecureStorageService(
        FlutterSecureStorage(
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
      );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
        key: AppConstants.secureKeyAccessToken, value: accessToken);
    await _storage.write(
        key: AppConstants.secureKeyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.secureKeyAccessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.secureKeyRefreshToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.secureKeyAccessToken);
    await _storage.delete(key: AppConstants.secureKeyRefreshToken);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
