import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/location/location_outbox_store.dart';
import 'package:eld_management_system/core/location/location_remote_datasource.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';

class LocationSyncService {
  LocationSyncService({
    required LocationOutboxStore outbox,
    required LocationRemoteDataSource remote,
    required SecureStorageService storage,
    Connectivity? connectivity,
  })  : _outbox = outbox,
        _remote = remote,
        _storage = storage,
        _connectivity = connectivity ?? Connectivity();

  final LocationOutboxStore _outbox;
  final LocationRemoteDataSource _remote;
  final SecureStorageService _storage;
  final Connectivity _connectivity;

  Future<bool> canSync() async {
    if (AppConstants.useDemoAuth) return false;
    final token = await _storage.getAccessToken();
    if (token == null || token.startsWith('demo_')) return false;
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<int> flushOutbox() async {
    if (!await canSync()) return 0;

    var totalAccepted = 0;
    while (true) {
      final pending = await _outbox.pending();
      if (pending.isEmpty) break;

      try {
        final result = await _remote.uploadBatch(
          pending.map((entry) => entry.point).toList(),
        );
        await _outbox.removeMany(result.accepted);

        for (final rejected in result.rejected) {
          await _outbox.markAttempt(pointId: rejected.id, error: rejected.reason);
        }

        totalAccepted += result.accepted.length;
        AppLogger.info('Location outbox flushed: ${result.accepted.length} accepted');

        if (result.accepted.isEmpty) break;
      } catch (e, st) {
        AppLogger.warning('Location outbox flush failed', e, st);
        for (final entry in pending) {
          await _outbox.markAttempt(pointId: entry.pointId, error: e.toString());
        }
        break;
      }
    }

    return totalAccepted;
  }
}