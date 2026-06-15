import 'package:hive_flutter/hive_flutter.dart';

/// Persists the Settings toggle for ELD & HOS driver alerts.
class NotificationPreferencesStore {
  NotificationPreferencesStore();

  static const _boxName = 'app_settings';
  static const _alertsEnabledKey = 'driver_alerts_enabled';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  Future<bool> areAlertsEnabled() async {
    final box = await _box();
    return box.get(_alertsEnabledKey, defaultValue: true) as bool;
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    final box = await _box();
    await box.put(_alertsEnabledKey, enabled);
  }
}