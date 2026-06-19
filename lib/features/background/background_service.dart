import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/features/background/background_sync.dart';
import 'package:workmanager/workmanager.dart';

/// Background sync and BLE persistence coordination.
abstract final class BackgroundService {
  static const String _taskName = AppConstants.workmanagerTaskSync;

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      AppLogger.info('Background workmanager registered');
    } catch (e) {
      AppLogger.warning(
        'Workmanager init skipped (platform may not support)',
        e,
      );
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.info('Background task: $task');
    if (task == AppConstants.workmanagerTaskSync) {
      await runBackgroundSync();
    }
    return Future.value(true);
  });
}
