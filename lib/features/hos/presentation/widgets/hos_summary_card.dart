import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';
import 'package:flutter/material.dart';

class HosSummaryCard extends StatelessWidget {
  const HosSummaryCard({required this.summary, super.key});

  final HosSummary summary;

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: summary.isInViolation
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hours of Service',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (summary.isInViolation) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.violationMessage ?? 'HOS violation',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _Row('Remaining drive', _formatMinutes(summary.remainingDriveMinutes)),
            _Row('Remaining on-duty', _formatMinutes(summary.remainingOnDutyMinutes)),
            _Row('Cycle remaining', _formatMinutes(summary.remainingCycleMinutes)),
            const Divider(height: 24),
            _Row('Driving today', _formatMinutes(summary.drivingMinutesToday)),
            _Row('On-duty today', _formatMinutes(summary.onDutyMinutesToday)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}