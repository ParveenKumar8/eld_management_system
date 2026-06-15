import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:flutter/material.dart';

class DutyStatusSelector extends StatelessWidget {
  const DutyStatusSelector({required this.onSelected, super.key});

  final ValueChanged<DutyStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: DutyStatus.values.map((status) {
        final (color, icon) = _style(status);
        return _DutyCard(
          label: status.displayName,
          icon: icon,
          color: color,
          onTap: () => onSelected(status),
        );
      }).toList(),
    );
  }

  (Color, IconData) _style(DutyStatus status) {
    switch (status) {
      case DutyStatus.driving:
        return (AppColors.amber, Icons.directions_car_filled_rounded);
      case DutyStatus.onDutyNotDriving:
        return (AppColors.teal, Icons.work_outline_rounded);
      case DutyStatus.offDuty:
        return (const Color(0xFF6366F1), Icons.weekend_rounded);
      case DutyStatus.sleeperBerth:
        return (const Color(0xFF8B5CF6), Icons.bed_rounded);
    }
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}