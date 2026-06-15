import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_catalog.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/strings/permission_strings.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Centralized, platform-aware permission checks and requests for ELD features.
class PermissionService {
  Future<List<PermissionStatusInfo>> checkStatuses() async {
    final items = await PermissionCatalog.applicableItems();
    final statuses = <PermissionStatusInfo>[];
    for (final item in items) {
      statuses.add(
        PermissionStatusInfo(
          kind: item.kind,
          status: await _aggregateStatus(item.permissions),
          required: item.required,
        ),
      );
    }
    return statuses;
  }

  Future<PermissionGrantResult> requestAll() async {
    final items = await PermissionCatalog.applicableItems();
    return _requestItems(items);
  }

  Future<PermissionGrantResult> requestOne(EldPermissionKind kind) async {
    final items = await PermissionCatalog.applicableItems();
    final match = items.where((i) => i.kind == kind).toList();
    if (match.isEmpty) {
      return PermissionGrantResult(
        allRequiredGranted: true,
        statuses: await checkStatuses(),
      );
    }
    return _requestItems(match);
  }

  Future<bool> openSettings() => ph.openAppSettings();

  Future<void> ensureRequiredGranted() async {
    final result = await requestAll();
    if (!result.allRequiredGranted) {
      throw PermissionException(
        result.message ?? PermissionStrings.deniedSummaryPrefix,
        code: 'permission_denied',
      );
    }
  }

  Future<PermissionGrantResult> _requestItems(List<PermissionCatalogItem> items) async {
    final requiredKinds = items.where((i) => i.required).map((i) => i.kind).toSet();

    for (final item in items.where((i) => i.required)) {
      final granted = await _requestCatalogItem(item);
      if (!granted) {
        return _deniedResult(requiredKinds);
      }
    }

    for (final item in items.where((i) => !i.required)) {
      await _requestCatalogItem(item);
    }

    final statuses = await checkStatuses();
    final allRequiredGranted = statuses
        .where((s) => s.required)
        .every((s) => s.isGranted);

    return PermissionGrantResult(
      allRequiredGranted: allRequiredGranted,
      statuses: statuses,
      message: allRequiredGranted
          ? null
          : PermissionStrings.deniedSummary(
              statuses.where((s) => s.required && !s.isGranted).map((s) => s.title),
            ),
    );
  }

  Future<PermissionGrantResult> _deniedResult(Set<EldPermissionKind> requiredKinds) async {
    final statuses = await checkStatuses();
    final deniedLabels = statuses
        .where((s) => requiredKinds.contains(s.kind) && !s.isGranted)
        .map((s) => s.title)
        .toList();

    return PermissionGrantResult(
      allRequiredGranted: false,
      statuses: statuses,
      message: PermissionStrings.deniedSummary(deniedLabels),
    );
  }

  Future<bool> _requestCatalogItem(PermissionCatalogItem item) async {
    if (item.kind == EldPermissionKind.locationAlways) {
      final whenInUse = await _whenInUseGranted();
      if (!whenInUse) {
        AppLogger.warning('Skipping background location until when-in-use is granted');
        return !item.required;
      }
    }

    for (final permission in item.permissions) {
      var status = await permission.status;
      if (status.isGranted) continue;
      if (status.isPermanentlyDenied) return false;

      status = await permission.request();
      if (!status.isGranted && !status.isLimited) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _whenInUseGranted() async {
    final whenInUseStatuses = await Future.wait([
      ph.Permission.locationWhenInUse.status,
      ph.Permission.location.status,
    ]);
    return whenInUseStatuses.any((s) => s.isGranted || s.isLimited);
  }

  Future<AppPermissionDisplayStatus> _aggregateStatus(List<ph.Permission> permissions) async {
    final statuses = await Future.wait(permissions.map((p) => p.status));
    if (statuses.every((s) => s.isGranted || s.isLimited)) {
      return statuses.any((s) => s.isLimited)
          ? AppPermissionDisplayStatus.limited
          : AppPermissionDisplayStatus.granted;
    }
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return AppPermissionDisplayStatus.permanentlyDenied;
    }
    if (statuses.any((s) => s.isRestricted)) {
      return AppPermissionDisplayStatus.restricted;
    }
    if (statuses.any((s) => s.isDenied)) {
      return AppPermissionDisplayStatus.denied;
    }
    return AppPermissionDisplayStatus.notDetermined;
  }
}