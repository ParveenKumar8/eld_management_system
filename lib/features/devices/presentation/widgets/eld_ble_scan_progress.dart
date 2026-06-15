import 'dart:async';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/strings/device_strings.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/devices/presentation/widgets/eld_ble_scan_radar.dart';
import 'package:eld_management_system/features/devices/presentation/widgets/eld_device_compatibility_badge.dart';
import 'package:flutter/material.dart';

/// Full-panel scanning progress shown while BLE discovery is running.
class EldBleScanProgress extends StatefulWidget {
  const EldBleScanProgress({
    required this.startedAt,
    required this.deviceCount,
    required this.devices,
    required this.onCancel,
    super.key,
  });

  final DateTime startedAt;
  final int deviceCount;
  final List<EldDevice> devices;
  final VoidCallback onCancel;

  @override
  State<EldBleScanProgress> createState() => _EldBleScanProgressState();
}

class _EldBleScanProgressState extends State<EldBleScanProgress> {
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _tick());
  }

  void _tick() {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final next = (elapsed.inMilliseconds / AppConstants.bleScanTimeout.inMilliseconds).clamp(0.0, 1.0);
    if (mounted && next != _progress) {
      setState(() => _progress = next);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_progress * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.navy.withValues(alpha: 0.04),
                  AppColors.teal.withValues(alpha: 0.08),
                  AppColors.amber.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                const EldBleScanRadar(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  DeviceStrings.scanningTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DeviceStrings.scanningSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: _progress,
                    backgroundColor: AppColors.navy.withValues(alpha: 0.08),
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DeviceStrings.scanningProgress(percent),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: widget.deviceCount > 0
                      ? _FoundChip(count: widget.deviceCount)
                      : Text(
                          DeviceStrings.scanningStillLooking,
                          key: const ValueKey('looking'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ],
            ),
          ),
          if (widget.devices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DeviceStrings.scanningDevicesFound(widget.deviceCount),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.devices.asMap().entries.map(
                  (entry) => EldFadeIn(
                    delay: Duration(milliseconds: 80 * entry.key),
                    child: _PreviewDeviceTile(device: entry.value),
                  ),
                ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(DeviceStrings.scanningCancel),
          ),
        ],
      ),
    );
  }
}

class _FoundChip extends StatelessWidget {
  const _FoundChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<int>(count),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Text(
            DeviceStrings.scanningDevicesFound(count),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDeviceTile extends StatelessWidget {
  const _PreviewDeviceTile({required this.device});

  final EldDevice device;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                EldDeviceCompatibilityBadge(compatibility: device.compatibility),
                const SizedBox(height: 4),
                Text(
                  DeviceStrings.signalDetail(device.rssi),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.radar_rounded, color: AppColors.amber, size: 18),
        ],
      ),
    );
  }
}