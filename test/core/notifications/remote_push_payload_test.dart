import 'package:eld_management_system/core/notifications/remote_push_payload.dart';
import 'package:eld_management_system/core/notifications/remote_push_type.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses remote message data payload with route override', () {
    final message = RemoteMessage(
      data: const {
        'type': 'hosViolation',
        'route': AppRoutes.logs,
        'detail': 'Exceeded 11-hour limit',
        'title': 'Fleet HOS alert',
        'body': 'Review your log immediately.',
      },
    );

    final payload = RemotePushPayload.fromRemoteMessage(message);
    expect(payload.type, RemotePushType.hosViolation);
    expect(payload.route, AppRoutes.logs);
    expect(payload.title, 'Fleet HOS alert');
    expect(payload.body, 'Review your log immediately.');
    expect(payload.detail, 'Exceeded 11-hour limit');
  });

  test('encodes and decodes remote tap payload', () {
    const payload = RemotePushPayload(
      type: RemotePushType.fleetMessage,
      route: AppRoutes.dashboard,
      title: 'Dispatch',
      body: 'New route assignment',
    );

    final restored = RemotePushPayload.decode(payload.encode());
    expect(restored?.type, RemotePushType.fleetMessage);
    expect(restored?.route, AppRoutes.dashboard);
  });

  test('maps unknown type to generic dashboard route', () {
    final message = RemoteMessage(data: const {'type': 'unknown_alert'});
    final payload = RemotePushPayload.fromRemoteMessage(message);
    expect(payload.type, RemotePushType.generic);
    expect(payload.route, AppRoutes.dashboard);
  });
}