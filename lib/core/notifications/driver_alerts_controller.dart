import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/core/notifications/driver_notification_dispatcher.dart';
import 'package:eld_management_system/core/notifications/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings toggle state for ELD & HOS driver alerts.
class DriverAlertsController extends StateNotifier<AsyncValue<bool>> {
  DriverAlertsController() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = AsyncValue.data(await sl<NotificationService>().areAlertsEnabled());
  }

  Future<bool> setEnabled(bool enabled) async {
    final service = sl<NotificationService>();
    if (enabled) {
      final granted = await service.requestPermissionIfNeeded();
      if (!granted) {
        state = AsyncValue.data(await service.areAlertsEnabled());
        return false;
      }
    } else {
      sl<DriverNotificationDispatcher>().resetHosWarnings();
    }

    await service.setAlertsEnabled(enabled);
    state = AsyncValue.data(enabled);
    return true;
  }
}

final driverAlertsEnabledProvider =
    StateNotifierProvider<DriverAlertsController, AsyncValue<bool>>(
  (ref) => DriverAlertsController(),
);