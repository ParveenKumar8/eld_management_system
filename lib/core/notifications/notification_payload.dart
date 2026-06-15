import 'dart:convert';

import 'package:eld_management_system/core/notifications/driver_notification_type.dart';
import 'package:equatable/equatable.dart';

/// Serialized into local notification payloads for tap handling.
class NotificationPayload extends Equatable {
  const NotificationPayload({
    required this.type,
    required this.route,
  });

  final DriverNotificationType type;
  final String route;

  String encode() => jsonEncode({
        'type': type.name,
        'route': route,
      });

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final typeName = map['type'] as String?;
      final route = map['route'] as String?;
      if (typeName == null || route == null) return null;
      final type = DriverNotificationType.values.byName(typeName);
      return NotificationPayload(type: type, route: route);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [type, route];
}