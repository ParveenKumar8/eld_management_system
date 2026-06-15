import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:flutter/material.dart';

class DutyStatusSelector extends StatelessWidget {
  const DutyStatusSelector({required this.onSelected, super.key});

  final ValueChanged<DutyStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DutyStatus.values.map((status) {
        return FilterChip(
          label: Text(status.displayName),
          selected: false,
          onSelected: (_) => onSelected(status),
          avatar: Icon(_iconFor(status), size: 18),
        );
      }).toList(),
    );
  }

  IconData _iconFor(DutyStatus status) {
    switch (status) {
      case DutyStatus.driving:
        return Icons.directions_car;
      case DutyStatus.onDutyNotDriving:
        return Icons.work;
      case DutyStatus.offDuty:
        return Icons.hotel;
      case DutyStatus.sleeperBerth:
        return Icons.bed;
    }
  }
}