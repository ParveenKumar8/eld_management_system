import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/location/location_sync_service.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_sync_service.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_sync_service.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_sync_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Entry point for Workmanager background sync (separate isolate).
Future<void> runBackgroundSync() async {
  try {
    await Hive.initFlutter();
    await configureDependencies();
    await sl<HosSyncService>().syncAll();
    await sl<EldSyncService>().flushOutbox();
    await sl<LocationSyncService>().flushOutbox();
    await sl<ProfileSyncService>().syncAll();
    AppLogger.info('Background sync complete (HOS + ELD + location + profile)');
  } catch (e, st) {
    AppLogger.warning('Background sync failed', e, st);
  }
}