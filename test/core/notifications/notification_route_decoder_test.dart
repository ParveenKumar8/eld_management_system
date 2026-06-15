import 'package:eld_management_system/core/notifications/driver_notification_type.dart';
import 'package:eld_management_system/core/notifications/notification_payload.dart';
import 'package:eld_management_system/core/notifications/notification_route_decoder.dart';
import 'package:eld_management_system/core/notifications/remote_push_payload.dart';
import 'package:eld_management_system/core/notifications/remote_push_type.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes local notification route', () {
    const payload = NotificationPayload(
      type: DriverNotificationType.eldDisconnected,
      route: AppRoutes.devices,
    );
    expect(NotificationRouteDecoder.decode(payload.encode()), AppRoutes.devices);
  });

  test('decodes remote notification route', () {
    const payload = RemotePushPayload(
      type: RemotePushType.complianceReminder,
      route: AppRoutes.reports,
      title: 'Compliance',
      body: 'Certify logs',
    );
    expect(NotificationRouteDecoder.decode(payload.encode()), AppRoutes.reports);
  });
}