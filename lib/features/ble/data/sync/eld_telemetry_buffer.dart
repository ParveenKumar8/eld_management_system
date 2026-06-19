import 'dart:async';

import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:eld_management_system/features/ble/data/datasources/eld_local_datasource.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_outbox_store.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_sync_service.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';
import 'package:uuid/uuid.dart';

/// Persists parsed BLE telemetry to Hive and queues server upload.
class EldTelemetryBuffer {
  EldTelemetryBuffer({
    required EldLocalDataSource local,
    required EldOutboxStore outbox,
    required EldSyncService sync,
    required AuthLocalDataSource authLocal,
  })  : _local = local,
        _outbox = outbox,
        _sync = sync,
        _authLocal = authLocal;

  final EldLocalDataSource _local;
  final EldOutboxStore _outbox;
  final EldSyncService _sync;
  final AuthLocalDataSource _authLocal;
  final _uuid = const Uuid();

  Future<void> append({
    required EldData data,
    required String deviceId,
  }) async {
    final user = await _authLocal.getCachedUser();
    final driverId = user?.id ?? 'unassigned';
    final record = EldTelemetryRecord(
      id: _uuid.v4(),
      driverId: driverId,
      deviceId: deviceId,
      data: data,
    );

    await _local.append(record);
    await _outbox.enqueue(record);

    unawaited(
      _sync.flushOutbox().catchError((Object e, StackTrace st) {
        AppLogger.warning('ELD immediate sync failed', e, st);
        return 0;
      }),
    );
  }
}