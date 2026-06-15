import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/widgets/eld_ring_progress.dart';
import 'package:eld_management_system/core/widgets/eld_status_badge.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';
import 'package:flutter/material.dart';

class HosSummaryCard extends StatelessWidget {
  const HosSummaryCard({required this.summary, super.key});

  final HosSummary summary;

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final driveProgress =
        summary.remainingDriveMinutes / AppConstants.maxDrivingMinutesPerDay;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: summary.isInViolation
              ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
              : [AppColors.navy, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hours of Service',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              EldStatusBadge(
                label: summary.isInViolation ? 'Violation' : 'Compliant',
                tone: summary.isInViolation ? EldBadgeTone.danger : EldBadgeTone.success,
              ),
            ],
          ),
          if (summary.isInViolation) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary.violationMessage ?? 'HOS violation detected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              EldRingProgress(
                progress: driveProgress,
                label: 'Drive left',
                value: _formatMinutes(summary.remainingDriveMinutes),
                color: AppColors.amber,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _MiniStat(
                      'On-duty left',
                      _formatMinutes(summary.remainingOnDutyMinutes),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MiniStat(
                      'Cycle left',
                      _formatMinutes(summary.remainingCycleMinutes),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MiniStat(
                      'Driving today',
                      _formatMinutes(summary.drivingMinutesToday),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}