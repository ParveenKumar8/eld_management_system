import 'dart:async';

import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/notifications/firebase_background_handler.dart';
import 'package:eld_management_system/core/notifications/notification_service.dart';
import 'package:eld_management_system/core/notifications/remote_push_payload.dart';
import 'package:eld_management_system/core/notifications/remote_push_token_datasource.dart';
import 'package:eld_management_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

typedef RemotePushTapCallback = void Function(RemotePushPayload payload);

/// Firebase Cloud Messaging — foreground, background, and terminated handling.
class RemotePushService {
  RemotePushService({
    required NotificationService notifications,
    required RemotePushTokenDataSource tokenDataSource,
    FirebaseMessaging? messaging,
  })  : _notifications = notifications,
        _tokenDataSource = tokenDataSource,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final NotificationService _notifications;
  final RemotePushTokenDataSource _tokenDataSource;
  final FirebaseMessaging _messaging;

  RemotePushTapCallback? _onTap;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  String? _currentToken;
  String? _boundDriverId;
  bool _initialized = false;

  bool get isAvailable => _initialized;

  Future<bool> initialize({required RemotePushTapCallback onTap}) async {
    if (_initialized) return true;
    _onTap = onTap;

    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (DefaultFirebaseOptions.isConfigured && options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
    } catch (e, st) {
      AppLogger.warning(
        'Firebase initialize failed — add google-services.json / GoogleService-Info.plist',
        e,
        st,
      );
      return false;
    }

    await _notifications.ensureRemoteChannel();
    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleTap(RemotePushPayload.fromRemoteMessage(initial));
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);
    _currentToken = await _messaging.getToken();

    _initialized = true;
    AppLogger.info('RemotePushService initialized');
    return true;
  }

  Future<void> bindDriver(String driverId) async {
    if (!_initialized) return;
    _boundDriverId = driverId;
    final token = _currentToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    _currentToken = token;
    await _tokenDataSource.registerToken(driverId: driverId, token: token);
  }

  Future<void> unbindDriver() async {
    if (!_initialized) return;
    final token = _currentToken;
    _boundDriverId = null;
    if (token == null) return;
    await _tokenDataSource.unregisterToken(token: token);
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _tokenRefreshSub = null;
    _initialized = false;
  }

  Future<void> _requestPermission() async {
    await _notifications.requestPermissionIfNeeded();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = RemotePushPayload.fromRemoteMessage(message);
    AppLogger.info('Foreground remote push: ${payload.type.name}');
    await _notifications.showRemote(payload);
  }

  void _onMessageOpened(RemoteMessage message) {
    _handleTap(RemotePushPayload.fromRemoteMessage(message));
  }

  void _handleTap(RemotePushPayload payload) {
    AppLogger.info('Remote push tapped: ${payload.type.name} → ${payload.route}');
    _onTap?.call(payload);
  }

  Future<void> _onTokenRefresh(String token) async {
    _currentToken = token;
    AppLogger.info('FCM token refreshed');
    final driverId = _boundDriverId;
    if (driverId != null) {
      await _tokenDataSource.registerToken(driverId: driverId, token: token);
    }
  }
}