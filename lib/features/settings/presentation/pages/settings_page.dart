import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/location/location_tracking_status.dart';
import 'package:eld_management_system/core/notifications/driver_alerts_controller.dart';
import 'package:eld_management_system/core/strings/location_strings.dart';
import 'package:eld_management_system/core/strings/notification_strings.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: EldScreen(
        child: ListView(
        padding: EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const EldPageHeader(title: 'Settings'),
          EldFadeIn(
            child: _SettingsGroup(
            title: 'Appearance',
            children: [
              _ThemeOption(
                label: 'System',
                icon: Icons.brightness_auto_rounded,
                selected: themeMode == AppThemeMode.system,
                onTap: () => ref.read(themeModeProvider.notifier).state = AppThemeMode.system,
              ),
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: themeMode == AppThemeMode.light,
                onTap: () => ref.read(themeModeProvider.notifier).state = AppThemeMode.light,
              ),
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: themeMode == AppThemeMode.dark,
                onTap: () => ref.read(themeModeProvider.notifier).state = AppThemeMode.dark,
              ),
            ],
          ),
          ),
          EldFadeIn(
            delay: const Duration(milliseconds: 80),
            child: _SettingsGroup(
              title: 'Notifications',
              children: const [
                _DriverAlertsToggle(),
              ],
            ),
          ),
          EldFadeIn(
            delay: const Duration(milliseconds: 160),
            child: _SettingsGroup(
            title: 'Privacy & Compliance',
            children: const [
              _LocationTrackingStatusTile(),
              _InfoTile(
                icon: Icons.shield_rounded,
                label: 'Crash Reporting',
                subtitle: 'Sentry integration placeholder',
              ),
              _InfoTile(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                subtitle: '1.0.0',
              ),
            ],
          ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.pagePadding(context).left,
        AppSpacing.md,
        Responsive.pagePadding(context).right,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.navy.withValues(alpha: 0.08)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.navy : Theme.of(context).colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? AppColors.navy : null),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.navy, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverAlertsToggle extends ConsumerWidget {
  const _DriverAlertsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(driverAlertsEnabledProvider);

    return alerts.when(
      loading: () => const _ToggleTile(
        icon: Icons.notifications_active_rounded,
        label: NotificationStrings.settingsToggleTitle,
        subtitle: NotificationStrings.settingsToggleSubtitle,
        value: true,
        onChanged: null,
      ),
      error: (_, __) => const _ToggleTile(
        icon: Icons.notifications_active_rounded,
        label: NotificationStrings.settingsToggleTitle,
        subtitle: NotificationStrings.settingsToggleSubtitle,
        value: false,
        onChanged: null,
      ),
      data: (enabled) => _ToggleTile(
        icon: Icons.notifications_active_rounded,
        label: NotificationStrings.settingsToggleTitle,
        subtitle: NotificationStrings.settingsToggleSubtitle,
        value: enabled,
        onChanged: (value) async {
          final ok = await ref.read(driverAlertsEnabledProvider.notifier).setEnabled(value);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(NotificationStrings.permissionRequired)),
            );
          }
        },
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LocationTrackingStatusTile extends ConsumerWidget {
  const _LocationTrackingStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(locationTrackingStatusProvider);

    return status.when(
      loading: () => const _InfoTile(
        icon: Icons.location_on_rounded,
        label: LocationStrings.settingsStatusTitle,
        subtitle: 'Checking GPS status…',
      ),
      error: (_, __) => const _InfoTile(
        icon: Icons.location_off_rounded,
        label: LocationStrings.settingsStatusTitle,
        subtitle: LocationStrings.permissionRequired,
      ),
      data: (value) => _InfoTile(
        icon: _iconFor(value),
        label: LocationStrings.settingsStatusTitle,
        subtitle: LocationStrings.statusSubtitle(value),
        trailing: value == LocationTrackingStatus.trackingBackground ||
                value == LocationTrackingStatus.trackingForeground
            ? const Icon(Icons.gps_fixed_rounded, color: AppColors.navy, size: 20)
            : null,
      ),
    );
  }

  IconData _iconFor(LocationTrackingStatus status) => switch (status) {
        LocationTrackingStatus.trackingForeground ||
        LocationTrackingStatus.trackingBackground =>
          Icons.my_location_rounded,
        LocationTrackingStatus.permissionDenied ||
        LocationTrackingStatus.serviceDisabled =>
          Icons.location_disabled_rounded,
        LocationTrackingStatus.idle => Icons.location_on_rounded,
      };
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}