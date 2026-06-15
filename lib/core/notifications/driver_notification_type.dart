import 'package:eld_management_system/router/app_router.dart';

enum DriverNotificationChannel { eld, hos }

/// Essential driver alerts with tap-navigation targets.
enum DriverNotificationType {
  eldConnected(
    id: 1001,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  eldDisconnected(
    id: 1002,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  eldReconnecting(
    id: 1003,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  eldConnectionError(
    id: 1004,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  eldScanComplete(
    id: 1005,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  eldScanEmpty(
    id: 1006,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  eldIncompatibleDevice(
    id: 1007,
    channel: DriverNotificationChannel.eld,
    route: AppRoutes.devices,
  ),
  hosViolation(
    id: 2001,
    channel: DriverNotificationChannel.hos,
    route: AppRoutes.logs,
  ),
  hosDriveLimitWarning(
    id: 2002,
    channel: DriverNotificationChannel.hos,
    route: AppRoutes.dashboard,
  ),
  hosOnDutyLimitWarning(
    id: 2003,
    channel: DriverNotificationChannel.hos,
    route: AppRoutes.dashboard,
  ),
  hosBreakRequired(
    id: 2004,
    channel: DriverNotificationChannel.hos,
    route: AppRoutes.logs,
  ),
  hosCycleLimitWarning(
    id: 2005,
    channel: DriverNotificationChannel.hos,
    route: AppRoutes.dashboard,
  );

  const DriverNotificationType({
    required this.id,
    required this.channel,
    required this.route,
  });

  final int id;
  final DriverNotificationChannel channel;
  final String route;

  String get androidChannelId => switch (channel) {
        DriverNotificationChannel.eld => 'eld_alerts',
        DriverNotificationChannel.hos => 'hos_alerts',
      };
}