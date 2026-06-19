import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_local_datasource.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_remote_datasource.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_outbox_store.dart';

class HosSyncService {
  HosSyncService({
    required HosOutboxStore outbox,
    required HosRemoteDataSource remote,
    required HosLocalDataSource local,
    required SecureStorageService storage,
    Connectivity? connectivity,
  })  : _outbox = outbox,
        _remote = remote,
        _local = local,
        _storage = storage,
        _connectivity = connectivity ?? Connectivity();

  final HosOutboxStore _outbox;
  final HosRemoteDataSource _remote;
  final HosLocalDataSource _local;
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

    final pending = await _outbox.pending();
    if (pending.isEmpty) return 0;

    try {
      final result = await _remote.syncRecords(
        pending.map((entry) => entry.record).toList(),
      );
      await _outbox.removeMany(result.accepted);

      for (final rejected in result.rejected) {
        await _outbox.markAttempt(recordId: rejected.id, error: rejected.reason);
      }

      AppLogger.info('HOS outbox flushed: ${result.accepted.length} accepted');
      return result.accepted.length;
    } catch (e, st) {
      AppLogger.warning('HOS outbox flush failed', e, st);
      for (final entry in pending) {
        await _outbox.markAttempt(recordId: entry.recordId, error: e.toString());
      }
      return 0;
    }
  }

  Future<int> pullAndMerge({int days = 8}) async {
    if (!await canSync()) return 0;

    try {
      final remoteRecords = await _remote.fetchRecords(days: days);
      await _local.mergeRecords(remoteRecords);
      AppLogger.info('HOS pull merged ${remoteRecords.length} records');
      return remoteRecords.length;
    } catch (e, st) {
      AppLogger.warning('HOS pull failed', e, st);
      return 0;
    }
  }

  Future<void> syncAll({int days = 8}) async {
    await flushOutbox();
    await pullAndMerge(days: days);
  }
}