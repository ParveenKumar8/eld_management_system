import 'package:eld_management_system/core/location/location_tracking_status.dart';

/// User-facing copy for GPS tracking and foreground service notifications.
abstract final class LocationStrings {
  static const foregroundNotificationTitle = 'ELD location tracking';
  static const foregroundNotificationBody =
      'Recording GPS for FMCSA-compliant duty logs while you drive.';
  static const foregroundChannelName = 'Location Tracking';

  static const settingsStatusTitle = 'Background Location';
  static const permissionRequired =
      'Enable location access (including background) for FMCSA compliance.';

  static String statusLabel(LocationTrackingStatus status) => switch (status) {
        LocationTrackingStatus.idle => 'Not tracking',
        LocationTrackingStatus.trackingForeground => 'Tracking (foreground)',
        LocationTrackingStatus.trackingBackground => 'Tracking (background)',
        LocationTrackingStatus.permissionDenied => 'Location permission required',
        LocationTrackingStatus.serviceDisabled => 'Location services disabled',
      };

  static String statusSubtitle(LocationTrackingStatus status) => switch (status) {
        LocationTrackingStatus.idle => 'Sign in to start GPS logging.',
        LocationTrackingStatus.trackingForeground =>
          'GPS is active while the app is open.',
        LocationTrackingStatus.trackingBackground =>
          'GPS continues when the app is inactive or in the background.',
        LocationTrackingStatus.permissionDenied =>
          'Grant location access in system settings.',
        LocationTrackingStatus.serviceDisabled =>
          'Turn on device location services to log duty positions.',
      };
}