import 'package:eld_management_system/core/strings/device_strings.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';
import 'package:flutter/material.dart';

class EldDeviceCompatibilityBadge extends StatelessWidget {
  const EldDeviceCompatibilityBadge({required this.compatibility, super.key});

  final EldDeviceCompatibility compatibility;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (compatibility) {
      EldDeviceCompatibility.compatible => (AppColors.success.withValues(alpha: 0.12), AppColors.success),
      EldDeviceCompatibility.likely => (AppColors.teal.withValues(alpha: 0.12), AppColors.teal),
      EldDeviceCompatibility.incompatible => (AppColors.danger.withValues(alpha: 0.12), AppColors.danger),
      EldDeviceCompatibility.unknown => (AppColors.navy.withValues(alpha: 0.08), AppColors.navy),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DeviceStrings.compatibilityLabel(compatibility),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}