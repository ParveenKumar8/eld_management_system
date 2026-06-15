import 'dart:convert';

import 'package:eld_management_system/core/notifications/remote_push_type.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Parsed FCM data payload used for display and tap navigation.
class RemotePushPayload extends Equatable {
  const RemotePushPayload({
    required this.type,
    required this.route,
    required this.title,
    required this.body,
    this.detail,
    this.messageId,
  });

  final RemotePushType type;
  final String route;
  final String title;
  final String body;
  final String? detail;
  final String? messageId;

  String encode() => jsonEncode({
        'source': 'remote',
        'type': type.name,
        'route': route,
        if (detail != null && detail!.isNotEmpty) 'detail': detail,
      });

  static RemotePushPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['source'] != 'remote') return null;
      final type = RemotePushType.fromName(map['type'] as String?);
      final route = (map['route'] as String?) ?? type.route;
      return RemotePushPayload(
        type: type,
        route: route,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        detail: map['detail'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static RemotePushPayload fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final type = RemotePushType.fromName(data['type'] ?? data['alert_type']);
    final route = data['route'] ?? type.route;
    final detail = data['detail'] ?? data['message_detail'];
    final notification = message.notification;

    return RemotePushPayload(
      type: type,
      route: route,
      title: notification?.title ?? data['title'] ?? _defaultTitle(type),
      body: notification?.body ?? data['body'] ?? _defaultBody(type, detail),
      detail: detail,
      messageId: message.messageId,
    );
  }

  static String _defaultTitle(RemotePushType type) => switch (type) {
        RemotePushType.hosViolation => 'HOS violation',
        RemotePushType.hosDriveLimitWarning => 'Driving time low',
        RemotePushType.hosOnDutyLimitWarning => 'On-duty window low',
        RemotePushType.hosBreakRequired => 'Rest break required',
        RemotePushType.hosCycleLimitWarning => 'Weekly cycle limit low',
        RemotePushType.eldDisconnected => 'ELD disconnected',
        RemotePushType.eldMalfunction => 'ELD malfunction',
        RemotePushType.fleetMessage => 'Fleet message',
        RemotePushType.complianceReminder => 'Compliance reminder',
        RemotePushType.documentRequired => 'Document required',
        RemotePushType.generic => 'Fleet alert',
      };

  static String _defaultBody(RemotePushType type, String? detail) {
    final extra = detail == null || detail.isEmpty ? '' : ' $detail';
    return switch (type) {
      RemotePushType.hosViolation =>
        'Your fleet reported an hours-of-service violation.$extra',
      RemotePushType.hosDriveLimitWarning =>
        'Less than 1 hour of drive time remains today.$extra',
      RemotePushType.hosOnDutyLimitWarning =>
        'Less than 1 hour remains in your on-duty window.$extra',
      RemotePushType.hosBreakRequired =>
        'A required off-duty reset was flagged by dispatch.$extra',
      RemotePushType.hosCycleLimitWarning =>
        'Weekly on-duty cycle is nearly exhausted.$extra',
      RemotePushType.eldDisconnected =>
        'Fleet reports your ELD connection was lost.$extra',
      RemotePushType.eldMalfunction =>
        'An ELD malfunction was reported for your vehicle.$extra',
      RemotePushType.fleetMessage => 'You have a new message from dispatch.$extra',
      RemotePushType.complianceReminder =>
        'A compliance task needs your attention.$extra',
      RemotePushType.documentRequired =>
        'A required document is pending in your account.$extra',
      RemotePushType.generic => 'Open the app to review this fleet alert.$extra',
    };
  }

  @override
  List<Object?> get props => [type, route, title, body, detail, messageId];
}