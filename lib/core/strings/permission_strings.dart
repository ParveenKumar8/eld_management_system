import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';

/// User-facing copy for permission prompts, rationales, and errors.
abstract final class PermissionStrings {
  static const gateTitle = 'Permissions required';
  static const gateSubtitle =
      'ELD device scanning and FMCSA logging need the access below. Grant each permission to continue.';
  static const grantAll = 'Grant all permissions';
  static const retry = 'Try again';
  static const openSettings = 'Open Settings';
  static const permanentlyDeniedHint =
      'One or more permissions are blocked. Open Settings to enable them for ELD Management.';
  static const deniedSummaryPrefix = 'Required permissions denied';

  static String titleFor(EldPermissionKind kind) => switch (kind) {
        EldPermissionKind.bluetooth => bluetoothTitle,
        EldPermissionKind.locationWhenInUse => locationWhenInUseTitle,
        EldPermissionKind.locationAlways => locationAlwaysTitle,
        EldPermissionKind.notification => notificationTitle,
      };

  static String rationaleFor(EldPermissionKind kind) => switch (kind) {
        EldPermissionKind.bluetooth => bluetoothRationale,
        EldPermissionKind.locationWhenInUse => locationWhenInUseRationale,
        EldPermissionKind.locationAlways => locationAlwaysRationale,
        EldPermissionKind.notification => notificationRationale,
      };

  static String statusLabel(AppPermissionDisplayStatus status) => switch (status) {
        AppPermissionDisplayStatus.granted => 'Granted',
        AppPermissionDisplayStatus.denied => 'Denied',
        AppPermissionDisplayStatus.permanentlyDenied => 'Blocked',
        AppPermissionDisplayStatus.restricted => 'Restricted',
        AppPermissionDisplayStatus.limited => 'Limited',
        AppPermissionDisplayStatus.notDetermined => 'Not requested',
      };

  static String deniedSummary(Iterable<String> labels) =>
      '$deniedSummaryPrefix: ${labels.join(', ')}';

  static const bluetoothTitle = 'Bluetooth';
  static const bluetoothRationale =
      'Connect to Geometris Whereqube and compatible ELD hardware over Bluetooth Low Energy.';

  static const locationWhenInUseTitle = 'Location while using app';
  static const locationWhenInUseRationale =
      'Attach GPS position to duty status and ELD records while you use the app.';

  static const locationAlwaysTitle = 'Background location';
  static const locationAlwaysRationale =
      'Keep FMCSA-compliant location on ELD records when the app runs in the background.';

  static const notificationTitle = 'Notifications';
  static const notificationRationale =
      'Show connection status and compliance alerts while the ELD service runs.';
}

/// UI-friendly permission status (decoupled from permission_handler).
enum AppPermissionDisplayStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  notDetermined,
}