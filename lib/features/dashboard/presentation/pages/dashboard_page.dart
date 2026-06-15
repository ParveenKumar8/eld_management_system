import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_metric_tile.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_section_header.dart';

import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/presentation/cubit/hos_cubit.dart';
import 'package:eld_management_system/features/hos/presentation/widgets/duty_status_selector.dart';
import 'package:eld_management_system/features/hos/presentation/widgets/hos_summary_card.dart';
import 'package:eld_management_system/features/maps/presentation/widgets/eld_live_map_card.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHos());
  }

  void _loadHos() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      ref.read(hosCubitProvider(auth.user.id)).load(auth.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const EldScreen(child: Center(child: CircularProgressIndicator()));
    }
    final driverId = authState.user.id;
    final hosCubit = ref.watch(hosCubitProvider(driverId));
    final isWide = Responsive.isTabletOrLarger(context);

    return BlocProvider.value(
      value: hosCubit,
      child: Scaffold(
        body: EldScreen(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async => hosCubit.load(driverId),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: EldFadeIn(
                    child: EldPageHeader(
                      greeting:
                          'Good day, ${authState.user.displayName.split(' ').first}',
                      title: 'Fleet Dashboard',
                      trailing: IconButton(
                        onPressed: () => context.push(AppRoutes.settings),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune_rounded, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.pagePadding(context).left,
                    0,
                    Responsive.pagePadding(context).right,
                    120,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: isWide
                        ? _TabletLayout(driverId: driverId, hosCubit: hosCubit)
                        : _PhoneLayout(driverId: driverId, hosCubit: hosCubit),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneLayout extends ConsumerWidget {
  const _PhoneLayout({required this.driverId, required this.hosCubit});
  final String driverId;
  final HosCubit hosCubit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricsRow(),
        const SizedBox(height: AppSpacing.md),
        _HosSection(hosCubit: hosCubit),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<EldBloc, EldState>(
          builder: (_, eld) => EldLiveMapCard(eldData: eld.latestData),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DutySection(driverId: driverId, hosCubit: hosCubit),
      ],
    );
  }
}

class _TabletLayout extends ConsumerWidget {
  const _TabletLayout({required this.driverId, required this.hosCubit});
  final String driverId;
  final HosCubit hosCubit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _MetricsRow(),
              const SizedBox(height: AppSpacing.md),
              _HosSection(hosCubit: hosCubit),
              const SizedBox(height: AppSpacing.lg),
              _DutySection(driverId: driverId, hosCubit: hosCubit),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 6,
          child: BlocBuilder<EldBloc, EldState>(
            builder: (_, eld) => EldLiveMapCard(
              eldData: eld.latestData,
              height: Responsive.mapHeight(context) + 80,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EldFadeIn(
      child: BlocBuilder<EldBloc, EldState>(
        builder: (context, eld) {
          final connected = eld.connectionState == EldConnectionState.connected;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: EldMetricTile(
                    icon: connected
                        ? Icons.bluetooth_connected_rounded
                        : Icons.bluetooth_disabled_rounded,
                    label: 'ELD Device',
                    value: connected ? 'Online' : 'Offline',
                    subtitle: _connectionLabel(eld.connectionState),
                    accentColor:
                        connected ? AppColors.success : AppColors.danger,
                    onTap: () => context.go(AppRoutes.devices),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: EldMetricTile(
                    icon: Icons.speed_rounded,
                    label: 'Speed',
                    value: eld.latestData != null
                        ? '${eld.latestData!.speedMph.toStringAsFixed(0)} mph'
                        : '—',
                    subtitle: eld.latestData?.isMoving == true
                        ? 'Moving'
                        : 'Stationary',
                    accentColor: AppColors.amber,
                  ),
                ),
              ],
            );
        },
      ),
    );
  }

  String _connectionLabel(EldConnectionState state) {
    switch (state) {
      case EldConnectionState.connected:
        return 'Tap to manage';
      case EldConnectionState.connecting:
        return 'Connecting…';
      case EldConnectionState.scanning:
        return 'Scanning…';
      case EldConnectionState.reconnecting:
        return 'Reconnecting…';
      case EldConnectionState.error:
        return 'Error';
      case EldConnectionState.disconnected:
        return 'Tap to connect';
    }
  }
}

class _HosSection extends StatelessWidget {
  const _HosSection({required this.hosCubit});
  final HosCubit hosCubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HosCubit, HosState>(
      bloc: hosCubit,
      builder: (context, hosState) {
        if (hosState.status == HosStatus.loading && hosState.summary == null) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (hosState.summary != null) {
          return EldFadeIn(
            delay: const Duration(milliseconds: 100),
            child: HosSummaryCard(summary: hosState.summary!),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DutySection extends ConsumerStatefulWidget {
  const _DutySection({required this.driverId, required this.hosCubit});
  final String driverId;
  final HosCubit hosCubit;

  @override
  ConsumerState<_DutySection> createState() => _DutySectionState();
}

class _DutySectionState extends ConsumerState<_DutySection> {
  Future<String?> _promptAnnotation(BuildContext context) async {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Annotation…')),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Confirm')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EldFadeIn(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EldSectionHeader(
            title: 'Change Duty Status',
            subtitle: 'FMCSA requires annotated status changes',
          ),
          DutyStatusSelector(
            onSelected: (status) async {
              final annotation = status == DutyStatus.offDuty
                  ? await _promptAnnotation(context)
                  : null;
              if (!context.mounted) return;
              await widget.hosCubit.changeStatus(
                driverId: widget.driverId,
                status: status,
                annotation: annotation,
              );
            },
          ),
        ],
      ),
    );
  }
}
