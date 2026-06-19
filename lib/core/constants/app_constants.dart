/// Application-wide constants for FMCSA ELD compliance.
abstract final class AppConstants {
  static const String appName = 'ELD Management System';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example-eld.com/v1',
  );
  static const bool useDemoAuth = bool.fromEnvironment(
    'USE_DEMO_AUTH',
    defaultValue: true,
  );
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // FMCSA HOS limits (property-carrying CMV, 60/7 rule baseline)
  static const int maxDrivingMinutesPerDay = 11 * 60;
  static const int maxOnDutyMinutesPerDay = 14 * 60;
  static const int requiredOffDutyMinutes = 10 * 60;
  static const int maxDrivingMinutesPerWeek = 60 * 60;

  // BLE - Geometris Whereqube common identifiers
  static const String geometrisDeviceNamePrefix = 'Whereqube';
  static const String geometrisServiceUuid =
      '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String geometrisNotifyUuid =
      '0000fff1-0000-1000-8000-00805f9b34fb';
  static const Duration bleScanTimeout = Duration(seconds: 15);

  // Storage keys
  static const String hiveBoxHos = 'hos_records';
  static const String hiveBoxHosOutbox = 'hos_outbox';
  static const String hiveBoxEld = 'eld_buffer';
  static const String hiveBoxEldOutbox = 'eld_outbox';
  static const String hiveBoxAuth = 'auth_cache';
  static const String hiveBoxLocation = 'location_trail';
  static const String hiveBoxLocationOutbox = 'location_outbox';
  static const String hiveBoxProfilePending = 'profile_pending';
  static const String secureKeyAccessToken = 'access_token';
  static const String secureKeyRefreshToken = 'refresh_token';

  // Background
  static const String androidForegroundChannelId = 'eld_connection_channel';
  static const String androidRemotePushChannelId = 'remote_push_alerts';
  static const String workmanagerTaskSync = 'eld_sync_task';
}
