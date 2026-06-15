import 'package:eld_management_system/core/notifications/driver_notification_type.dart';
import 'package:eld_management_system/core/notifications/notification_payload.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes and decodes notification payload', () {
    const payload = NotificationPayload(
      type: DriverNotificationType.hosViolation,
      route: AppRoutes.logs,
    );

    final decoded = NotificationPayload.decode(payload.encode());
    expect(decoded, payload);
  });

  test('maps ELD notifications to devices route', () {
    expect(DriverNotificationType.eldDisconnected.route, AppRoutes.devices);
    expect(DriverNotificationType.eldScanComplete.route, AppRoutes.devices);
  });

  test('maps HOS violation to logs route', () {
    expect(DriverNotificationType.hosViolation.route, AppRoutes.logs);
    expect(DriverNotificationType.hosDriveLimitWarning.route, AppRoutes.dashboard);
  });
}