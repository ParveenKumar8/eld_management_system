import 'dart:async';

import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:eld_management_system/core/location/location_outbox_store.dart';
import 'package:eld_management_system/core/location/location_sync_service.dart';
import 'package:eld_management_system/core/location/location_trail_point.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Queues persisted GPS fixes for server upload.
class LocationTrailBuffer {
  LocationTrailBuffer({
    required LocationOutboxStore outbox,
    required LocationSyncService sync,
  })  : _outbox = outbox,
        _sync = sync;

  final LocationOutboxStore _outbox;
  final LocationSyncService _sync;
  final _uuid = const Uuid();

  Future<void> append({
    required String driverId,
    required LocationFix fix,
  }) async {
    final point = LocationTrailPoint(
      id: _uuid.v4(),
      driverId: driverId,
      fix: fix,
    );
    await _outbox.enqueue(point);

    unawaited(
      _sync.flushOutbox().catchError((Object e, StackTrace st) {
        AppLogger.warning('Location immediate sync failed', e, st);
        return 0;
      }),
    );
  }
}