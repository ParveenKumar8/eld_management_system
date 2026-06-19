import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';
import 'package:eld_management_system/features/ble/data/datasources/eld_local_datasource.dart';
import 'package:eld_management_system/features/ble/data/datasources/eld_remote_datasource.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_outbox_store.dart';

class EldSyncService {
  EldSyncService({
    required EldOutboxStore outbox,
    required EldRemoteDataSource remote,
    required EldLocalDataSource local,
    required SecureStorageService storage,
    Connectivity? connectivity,
  })  : _outbox = outbox,
        _remote = remote,
        _local = local,
        _storage = storage,
        _connectivity = connectivity ?? Connectivity();

  final EldOutboxStore _outbox;
  final EldRemoteDataSource _remote;
  final EldLocalDataSource _local;
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
          pending.map((entry) => entry.record).toList(),
        );
        await _outbox.removeMany(result.accepted);
        await _local.removeMany(result.accepted);

        for (final rejected in result.rejected) {
          await _outbox.markAttempt(eventId: rejected.id, error: rejected.reason);
        }

        totalAccepted += result.accepted.length;
        AppLogger.info('ELD outbox flushed: ${result.accepted.length} accepted');

        if (result.accepted.isEmpty) break;
      } catch (e, st) {
        AppLogger.warning('ELD outbox flush failed', e, st);
        for (final entry in pending) {
          await _outbox.markAttempt(eventId: entry.eventId, error: e.toString());
        }
        break;
      }
    }

    return totalAccepted;
  }
}