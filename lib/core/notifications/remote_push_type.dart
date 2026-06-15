import 'package:eld_management_system/router/app_router.dart';

/// Remote fleet/dispatcher push categories with tap-navigation targets.
enum RemotePushType {
  hosViolation(route: AppRoutes.logs),
  hosDriveLimitWarning(route: AppRoutes.dashboard),
  hosOnDutyLimitWarning(route: AppRoutes.dashboard),
  hosBreakRequired(route: AppRoutes.logs),
  hosCycleLimitWarning(route: AppRoutes.dashboard),
  eldDisconnected(route: AppRoutes.devices),
  eldMalfunction(route: AppRoutes.devices),
  fleetMessage(route: AppRoutes.dashboard),
  complianceReminder(route: AppRoutes.reports),
  documentRequired(route: AppRoutes.reports),
  generic(route: AppRoutes.dashboard);

  const RemotePushType({required this.route});

  final String route;

  static RemotePushType fromName(String? raw) {
    if (raw == null || raw.isEmpty) return RemotePushType.generic;
    final normalized = raw.trim();
    for (final type in RemotePushType.values) {
      if (type.name == normalized) return type;
    }
    const aliases = <String, RemotePushType>{
      'eldConnectionError': RemotePushType.eldMalfunction,
      'eldIncompatibleDevice': RemotePushType.eldMalfunction,
      'eldReconnecting': RemotePushType.eldDisconnected,
    };
    return aliases[normalized] ?? RemotePushType.generic;
  }
}