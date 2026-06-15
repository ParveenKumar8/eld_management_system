import 'dart:io';

import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/notifications/driver_notification_type.dart';
import 'package:eld_management_system/core/notifications/notification_payload.dart';
import 'package:eld_management_system/core/notifications/remote_push_payload.dart';
import 'package:eld_management_system/core/notifications/notification_preferences_store.dart';
import 'package:eld_management_system/core/strings/notification_strings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NotificationTapCallback = void Function(String encodedPayload);

/// Local notifications for iOS and Android with channel setup and tap payloads.
class NotificationService {
  NotificationService({
    NotificationPreferencesStore? preferences,
    FlutterLocalNotificationsPlugin? plugin,
  })  : _preferences = preferences ?? NotificationPreferencesStore(),
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final NotificationPreferencesStore _preferences;
  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapCallback? _onTap;
  bool _initialized = false;

  Future<void> initialize({required NotificationTapCallback onTap}) async {
    if (_initialized) return;
    _onTap = onTap;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && launchResponse != null) {
      _handleNotificationResponse(launchResponse);
    }

    await _createChannels();
    _initialized = true;
    AppLogger.info('NotificationService initialized');
  }

  Future<bool> requestPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return true;
    final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  Future<bool> areAlertsEnabled() => _preferences.areAlertsEnabled();

  Future<void> setAlertsEnabled(bool enabled) async {
    await _preferences.setAlertsEnabled(enabled);
    if (!enabled) {
      await _plugin.cancelAll();
    }
  }

  Future<void> ensureRemoteChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.androidRemotePushChannelId,
        NotificationStrings.channelRemoteName,
        description: NotificationStrings.channelRemoteDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> showRemote(RemotePushPayload payload) async {
    if (!_initialized) return;
    if (!await _preferences.areAlertsEnabled()) return;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.androidRemotePushChannelId,
      NotificationStrings.channelRemoteName,
      channelDescription: NotificationStrings.channelRemoteDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final id = payload.messageId?.hashCode ?? payload.type.index + 3000;
    await _plugin.show(
      id,
      payload.title,
      payload.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload.encode(),
    );
  }

  Future<void> show(
    DriverNotificationType type, {
    String? detail,
  }) async {
    if (!_initialized) return;
    if (!await _preferences.areAlertsEnabled()) return;

    final payload = NotificationPayload(type: type, route: type.route);
    final androidDetails = AndroidNotificationDetails(
      type.androidChannelId,
      _channelName(type.channel),
      channelDescription: _channelDescription(type.channel),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      type.id,
      NotificationStrings.titleFor(type),
      NotificationStrings.bodyFor(type, detail: detail),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload.encode(),
    );
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'eld_alerts',
        NotificationStrings.channelEldName,
        description: NotificationStrings.channelEldDescription,
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'hos_alerts',
        NotificationStrings.channelHosName,
        description: NotificationStrings.channelHosDescription,
        importance: Importance.high,
      ),
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (_onTap == null || response.payload == null) return;
    _onTap!(response.payload!);
  }

  String _channelName(DriverNotificationChannel channel) => switch (channel) {
        DriverNotificationChannel.eld => NotificationStrings.channelEldName,
        DriverNotificationChannel.hos => NotificationStrings.channelHosName,
      };

  String _channelDescription(DriverNotificationChannel channel) => switch (channel) {
        DriverNotificationChannel.eld => NotificationStrings.channelEldDescription,
        DriverNotificationChannel.hos => NotificationStrings.channelHosDescription,
      };
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  // Navigation is handled on next foreground launch via getNotificationAppLaunchDetails.
}