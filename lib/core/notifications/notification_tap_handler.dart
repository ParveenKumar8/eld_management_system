import 'package:eld_management_system/core/notifications/notification_payload.dart';
import 'package:eld_management_system/core/notifications/notification_route_decoder.dart';
import 'package:eld_management_system/core/notifications/remote_push_payload.dart';
import 'package:go_router/go_router.dart';

/// Routes the driver to the correct screen when a notification is tapped.
class NotificationTapHandler {
  GoRouter? _router;
  String? _pendingRoute;

  void attach(GoRouter router) {
    _router = router;
    final pending = _pendingRoute;
    if (pending != null) {
      _navigate(pending);
      _pendingRoute = null;
    }
  }

  void handle(NotificationPayload payload) => handleRoute(payload.route);

  void handleRemote(RemotePushPayload payload) => handleRoute(payload.route);

  void handleRawPayload(String? raw) {
    final route = NotificationRouteDecoder.decode(raw);
    if (route != null) handleRoute(route);
  }

  void handleRoute(String route) {
    if (_router == null) {
      _pendingRoute = route;
      return;
    }
    _navigate(route);
  }

  void _navigate(String route) {
    final router = _router;
    if (router == null) return;
    router.go(route);
  }
}