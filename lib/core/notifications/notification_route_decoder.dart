import 'dart:convert';

import 'package:eld_management_system/core/notifications/notification_payload.dart';
import 'package:eld_management_system/core/notifications/remote_push_payload.dart';

/// Extracts a navigation route from local or remote notification payloads.
abstract final class NotificationRouteDecoder {
  static String? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final remote = RemotePushPayload.decode(raw);
    if (remote != null) return remote.route;

    final local = NotificationPayload.decode(raw);
    if (local != null) return local.route;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['route'] as String?;
    } catch (_) {
      return null;
    }
  }
}