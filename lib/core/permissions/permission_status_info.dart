import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/strings/permission_strings.dart';
import 'package:equatable/equatable.dart';

/// Snapshot of one logical permission for dynamic UI rendering.
class PermissionStatusInfo extends Equatable {
  const PermissionStatusInfo({
    required this.kind,
    required this.status,
    required this.required,
  });

  final EldPermissionKind kind;
  final AppPermissionDisplayStatus status;
  final bool required;

  bool get isGranted => status == AppPermissionDisplayStatus.granted;

  bool get needsSettings => status == AppPermissionDisplayStatus.permanentlyDenied;

  String get title => PermissionStrings.titleFor(kind);

  String get rationale => PermissionStrings.rationaleFor(kind);

  String get statusLabel => PermissionStrings.statusLabel(status);

  @override
  List<Object?> get props => [kind, status, required];
}

/// Outcome of a permission request flow.
class PermissionGrantResult extends Equatable {
  const PermissionGrantResult({
    required this.allRequiredGranted,
    required this.statuses,
    this.message,
  });

  final bool allRequiredGranted;
  final List<PermissionStatusInfo> statuses;
  final String? message;

  @override
  List<Object?> get props => [allRequiredGranted, statuses, message];
}