import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_empty_state.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_timeline_tile.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/presentation/cubit/hos_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  bool _inspectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        ref.read(hosCubitProvider(auth.user.id)).load(auth.user.id);
      }
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
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();

    final cubit = ref.watch(hosCubitProvider(auth.user.id));

    final padding = Responsive.pagePadding(context);

    return Scaffold(
      body: EldScreen(
        bottom: false,
        child: Column(
        children: [
          EldPageHeader(
            title: _inspectionMode ? 'Inspection Mode' : 'HOS Timeline',
            trailing: IconButton(
              onPressed: () => setState(() => _inspectionMode = !_inspectionMode),
              icon: Icon(
                _inspectionMode ? Icons.visibility_off_rounded : Icons.verified_user_rounded,
                color: _inspectionMode ? AppColors.amber : null,
              ),
            ),
          ),
          if (_inspectionMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.policy_rounded, color: AppColors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Roadside inspection view — read-only, FMCSA formatted.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<HosCubit, HosState>(
              bloc: cubit,
              builder: (context, state) {
                if (state.status == HosStatus.loading && state.records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.records.isEmpty) {
                  return const EldEmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'No logs yet',
                    subtitle: 'Duty status changes will appear here automatically.',
                  );
                }
                final fmt = DateFormat('MMM d · HH:mm');
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(padding.left, AppSpacing.md, padding.right, 120),
                  itemCount: state.records.length,
                  itemBuilder: (_, i) {
                    final r = state.records[i];
                    final time = '${fmt.format(r.startTime.toLocal())}'
                        '${r.endTime != null ? ' – ${fmt.format(r.endTime!.toLocal())}' : ' (active)'}';
                    return EldFadeIn(
                      delay: Duration(milliseconds: 40 * (i % 8)),
                      child: EldTimelineTile(
                      title: r.status.displayName,
                      subtitle: r.annotation ?? 'No annotation',
                      time: time,
                      accentColor: _colorFor(r.status),
                      isFirst: i == 0,
                      isLast: i == state.records.length - 1,
                      trailing: r.isEdited
                          ? const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.amber)
                          : null,
                    ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}