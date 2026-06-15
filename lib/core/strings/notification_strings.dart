import 'package:eld_management_system/core/notifications/driver_notification_type.dart';

/// User-facing notification copy and Settings labels.
abstract final class NotificationStrings {
  static const settingsToggleTitle = 'ELD & HOS Alerts';
  static const settingsToggleSubtitle =
      'Local and fleet push alerts for HOS, ELD status, and dispatch messages.';
  static const permissionRequired =
      'Enable notifications in system settings to receive driver alerts.';
  static const channelEldName = 'ELD Alerts';
  static const channelEldDescription = 'Bluetooth ELD connection and device status';
  static const channelHosName = 'HOS Alerts';
  static const channelHosDescription = 'Hours-of-service limits, violations, and break reminders';
  static const channelRemoteName = 'Fleet Push Alerts';
  static const channelRemoteDescription =
      'Remote notifications from dispatch and fleet management';

  static String titleFor(DriverNotificationType type) => switch (type) {
        DriverNotificationType.eldConnected => 'ELD connected',
        DriverNotificationType.eldDisconnected => 'ELD disconnected',
        DriverNotificationType.eldReconnecting => 'Reconnecting to ELD',
        DriverNotificationType.eldConnectionError => 'ELD connection error',
        DriverNotificationType.eldScanComplete => 'BLE scan complete',
        DriverNotificationType.eldScanEmpty => 'No Bluetooth devices found',
        DriverNotificationType.eldIncompatibleDevice => 'Device not ELD-compatible',
        DriverNotificationType.hosViolation => 'HOS violation',
        DriverNotificationType.hosDriveLimitWarning => 'Driving time low',
        DriverNotificationType.hosOnDutyLimitWarning => 'On-duty window low',
        DriverNotificationType.hosBreakRequired => 'Rest break required',
        DriverNotificationType.hosCycleLimitWarning => 'Weekly cycle limit low',
      };

  static String bodyFor(DriverNotificationType type, {String? detail}) {
    final extra = detail == null || detail.isEmpty ? '' : ' $detail';
    return switch (type) {
      DriverNotificationType.eldConnected =>
        'Your ELD is connected and logging data.$extra',
      DriverNotificationType.eldDisconnected =>
        'Connection to the ELD was lost. Tap to reconnect.$extra',
      DriverNotificationType.eldReconnecting =>
        'Attempting to restore the ELD Bluetooth link.$extra',
      DriverNotificationType.eldConnectionError =>
        'Could not maintain the ELD connection. Tap to troubleshoot.$extra',
      DriverNotificationType.eldScanComplete =>
        'Nearby Bluetooth devices are ready to review.$extra',
      DriverNotificationType.eldScanEmpty =>
        'No devices were detected. Tap to scan again.$extra',
      DriverNotificationType.eldIncompatibleDevice =>
        'The selected device is not ELD-compatible. Tap to choose another unit.$extra',
      DriverNotificationType.hosViolation =>
        'FMCSA hours-of-service limit exceeded.$extra',
      DriverNotificationType.hosDriveLimitWarning =>
        'Less than 1 hour of drive time remains today.$extra',
      DriverNotificationType.hosOnDutyLimitWarning =>
        'Less than 1 hour remains in your 14-hour on-duty window.$extra',
      DriverNotificationType.hosBreakRequired =>
        'A 10-hour off-duty reset may be required soon.$extra',
      DriverNotificationType.hosCycleLimitWarning =>
        'Weekly on-duty cycle is nearly exhausted.$extra',
    };
  }
}