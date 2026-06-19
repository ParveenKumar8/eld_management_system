import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:eld_management_system/features/auth/data/datasources/driver_remote_datasource.dart';
import 'package:eld_management_system/features/auth/data/models/user_model.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_pending_store.dart';

class ProfileSyncService {
  ProfileSyncService({
    required DriverRemoteDataSource remote,
    required AuthLocalDataSource local,
    required ProfilePendingStore pending,
    required SecureStorageService storage,
    Connectivity? connectivity,
  })  : _remote = remote,
        _local = local,
        _pending = pending,
        _storage = storage,
        _connectivity = connectivity ?? Connectivity();

  final DriverRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final ProfilePendingStore _pending;
  final SecureStorageService _storage;
  final Connectivity _connectivity;

  Future<bool> canSync() async {
    if (AppConstants.useDemoAuth) return false;
    final token = await _storage.getAccessToken();
    if (token == null || token.startsWith('demo_')) return false;
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<UserModel?> pullFromServer() async {
    if (!await canSync()) return null;

    try {
      final profile = await _remote.getDriverProfile();
      await _local.updateCachedUser(profile);
      AppLogger.info('Profile pulled from server for ${profile.email}');
      return profile;
    } catch (e, st) {
      AppLogger.warning('Profile pull failed', e, st);
      return null;
    }
  }

  Future<bool> pushPending() async {
    if (!await canSync()) return false;

    final pending = await _pending.get();
    if (pending == null) return false;

    try {
      final updated = await _remote.updateDriverProfile(
        displayName: pending.displayName,
        licenseNumber: pending.licenseNumber,
      );
      await _local.updateCachedUser(updated);
      await _pending.clear();
      AppLogger.info('Profile pending update pushed for ${updated.email}');
      return true;
    } catch (e, st) {
      AppLogger.warning('Profile push failed', e, st);
      return false;
    }
  }

  Future<UserModel?> syncAll() async {
    await pushPending();
    return pullFromServer();
  }
}