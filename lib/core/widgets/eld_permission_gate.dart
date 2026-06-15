import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_catalog.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/strings/permission_strings.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/widgets/eld_primary_button.dart';
import 'package:flutter/material.dart';

/// Dynamic permission rationale UI driven by [PermissionStatusInfo] from the catalog.
class EldPermissionGate extends StatelessWidget {
  const EldPermissionGate({
    super.key,
    required this.statuses,
    required this.onGrantAll,
    required this.onRetry,
    required this.onOpenSettings,
    this.onRequestItem,
    this.isLoading = false,
  });

  final List<PermissionStatusInfo> statuses;
  final VoidCallback onGrantAll;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  final void Function(EldPermissionKind kind)? onRequestItem;
  final bool isLoading;

  bool get _hasBlocked => statuses.any((s) => s.needsSettings);

  bool get _allRequiredGranted =>
      statuses.where((s) => s.required).every((s) => s.isGranted);

  @override
  Widget build(BuildContext context) {
    if (_allRequiredGranted) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  PermissionStrings.gateTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            PermissionStrings.gateSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...statuses.map(
            (item) => _PermissionRow(
              item: item,
              onRequest: onRequestItem,
            ),
          ),
          if (_hasBlocked) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              PermissionStrings.permanentlyDeniedHint,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: EldPrimaryButton(
                  label: isLoading ? PermissionStrings.retry : PermissionStrings.grantAll,
                  icon: Icons.verified_user_outlined,
                  onPressed: isLoading ? null : onGrantAll,
                ),
              ),
              if (_hasBlocked) ...[
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text(PermissionStrings.openSettings),
                ),
              ] else ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: isLoading ? null : onRetry,
                  child: const Text(PermissionStrings.retry),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.item, this.onRequest});

  final PermissionStatusInfo item;
  final void Function(EldPermissionKind kind)? onRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tone(item.status);
    final canRequest = onRequest != null &&
        !item.isGranted &&
        item.status != AppPermissionDisplayStatus.permanentlyDenied &&
        item.status != AppPermissionDisplayStatus.restricted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: canRequest ? () => onRequest!(item.kind) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  PermissionCatalog.iconFor(item.kind),
                  size: 20,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.rationale,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(label: item.statusLabel, tone: tone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ChipTone _tone(AppPermissionDisplayStatus status) => switch (status) {
        AppPermissionDisplayStatus.granted => _ChipTone.success,
        AppPermissionDisplayStatus.limited => _ChipTone.warning,
        AppPermissionDisplayStatus.denied => _ChipTone.warning,
        AppPermissionDisplayStatus.notDetermined => _ChipTone.neutral,
        AppPermissionDisplayStatus.permanentlyDenied => _ChipTone.danger,
        AppPermissionDisplayStatus.restricted => _ChipTone.danger,
      };
}

enum _ChipTone { success, warning, danger, neutral }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      _ChipTone.success => (AppColors.teal.withValues(alpha: 0.12), AppColors.teal),
      _ChipTone.warning => (AppColors.amber.withValues(alpha: 0.15), AppColors.amber),
      _ChipTone.danger => (AppColors.danger.withValues(alpha: 0.12), AppColors.danger),
      _ChipTone.neutral => (AppColors.navy.withValues(alpha: 0.08), AppColors.navy),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}