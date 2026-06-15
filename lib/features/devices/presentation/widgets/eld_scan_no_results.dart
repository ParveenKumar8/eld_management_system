import 'package:eld_management_system/core/strings/device_strings.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Animated empty state shown after a scan completes with no devices.
class EldScanNoResults extends StatelessWidget {
  const EldScanNoResults({required this.onScanAgain, super.key});

  final VoidCallback onScanAgain;

  static const _tips = [
    (Icons.power_settings_new_rounded, DeviceStrings.noResultsTipPower),
    (Icons.near_me_rounded, DeviceStrings.noResultsTipRange),
    (Icons.bluetooth_rounded, DeviceStrings.noResultsTipBluetooth),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EldFadeIn(
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.amber.withValues(alpha: 0.1),
                      ),
                    ),
                    Lottie.asset(
                      'assets/animations/ble_connect.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_off_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            EldFadeIn(
              delay: const Duration(milliseconds: 100),
              child: Text(
                DeviceStrings.noResultsTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            EldFadeIn(
              delay: const Duration(milliseconds: 180),
              child: Text(
                DeviceStrings.noResultsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._tips.asMap().entries.map(
                  (entry) => EldFadeIn(
                    delay: Duration(milliseconds: 240 + (entry.key * 80)),
                    child: _TipRow(icon: entry.value.$1, label: entry.value.$2),
                  ),
                ),
            const SizedBox(height: AppSpacing.xl),
            EldFadeIn(
              delay: const Duration(milliseconds: 520),
              child: EldPrimaryButton(
                label: DeviceStrings.scanAgain,
                icon: Icons.radar_rounded,
                onPressed: onScanAgain,
                expand: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}