import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/notifications/remote_push_payload.dart';
import 'package:eld_management_system/core/strings/notification_strings.dart';
import 'package:eld_management_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background FCM entry point — shows a local notification for data-only pushes.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (DefaultFirebaseOptions.isConfigured && options != null) {
      await Firebase.initializeApp(options: options);
    } else {
      await Firebase.initializeApp();
    }
  } catch (_) {
    return;
  }

  final payload = RemotePushPayload.fromRemoteMessage(message);
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await plugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      AppConstants.androidRemotePushChannelId,
      NotificationStrings.channelRemoteName,
      description: NotificationStrings.channelRemoteDescription,
      importance: Importance.high,
    ),
  );

  final encoded = payload.encode();
  final notificationId = payload.messageId?.hashCode ?? payload.type.index + 3000;

  await plugin.show(
    notificationId,
    payload.title,
    payload.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.androidRemotePushChannelId,
        NotificationStrings.channelRemoteName,
        channelDescription: NotificationStrings.channelRemoteDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: encoded,
  );

  AppLogger.info('Background remote push displayed: ${payload.type.name}');
}