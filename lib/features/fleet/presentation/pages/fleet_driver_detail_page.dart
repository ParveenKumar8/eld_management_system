import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_timeline_tile.dart';
import 'package:eld_management_system/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/presentation/widgets/hos_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FleetDriverDetailPage extends ConsumerStatefulWidget {
  const FleetDriverDetailPage({required this.driverId, super.key});

  final String driverId;

  @override
  ConsumerState<FleetDriverDetailPage> createState() => _FleetDriverDetailPageState();
}

class _FleetDriverDetailPageState extends ConsumerState<FleetDriverDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fleetCubitProvider).selectDriver(widget.driverId);
    });
  }

  Color _colorFor(DutyStatus status) {
    switch (status) {
      case DutyStatus.driving:
        return AppColors.amber;
      case DutyStatus.onDutyNotDriving:
        return AppColors.teal;
      case DutyStatus.offDuty:
        return const Color(0xFF6366F1);
      case DutyStatus.sleeperBerth:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = ref.watch(fleetCubitProvider);
    final padding = Responsive.pagePadding(context);
    final driver = cubit.state.selectedDriver;
    final fmt = DateFormat('MMM d · HH:mm');

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: EldScreen(
          bottom: false,
          child: BlocBuilder<FleetCubit, FleetState>(
            builder: (context, state) {
              if (state.status == FleetStatus.loading && state.selectedSummary == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 120),
                children: [
                  EldPageHeader(
                    title: driver?.displayName ?? 'Driver',
                    greeting: driver?.email,
                    trailing: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  if (state.selectedSummary != null)
                    EldFadeIn(child: HosSummaryCard(summary: state.selectedSummary!)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Recent logs (read-only)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.selectedRecords.isEmpty)
                    Text(
                      'No logs in the rolling 8-day window.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  else
                    ...state.selectedRecords.asMap().entries.map((entry) {
                      final record = entry.value;
                      final time = '${fmt.format(record.startTime.toLocal())}'
                          '${record.endTime != null ? ' – ${fmt.format(record.endTime!.toLocal())}' : ' (active)'}';
                      return EldFadeIn(
                        delay: Duration(milliseconds: 30 * (entry.key % 6)),
                        child: EldTimelineTile(
                          title: record.status.displayName,
                          subtitle: record.annotation ?? 'No annotation',
                          time: time,
                          accentColor: _colorFor(record.status),
                          isFirst: entry.key == 0,
                          isLast: entry.key == state.selectedRecords.length - 1,
                          trailing: record.isEdited
                              ? const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.amber)
                              : null,
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}