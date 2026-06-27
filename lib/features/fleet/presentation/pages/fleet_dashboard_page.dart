import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_empty_state.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_metric_tile.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_status_badge.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_driver_snapshot.dart';
import 'package:eld_management_system/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FleetDashboardPage extends ConsumerStatefulWidget {
  const FleetDashboardPage({super.key});

  @override
  ConsumerState<FleetDashboardPage> createState() => _FleetDashboardPageState();
}

class _FleetDashboardPageState extends ConsumerState<FleetDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fleetCubitProvider).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return const EldScreen(child: Center(child: CircularProgressIndicator()));
    }

    final cubit = ref.watch(fleetCubitProvider);
    final padding = Responsive.pagePadding(context);
    final isWide = Responsive.isTabletOrLarger(context);

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: EldScreen(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => cubit.loadDashboard(),
            child: BlocBuilder<FleetCubit, FleetState>(
              builder: (context, state) {
                if (state.status == FleetStatus.loading && state.drivers.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
                    ],
                  );
                }

                final overview = state.overview;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 120),
                  children: [
                    EldFadeIn(
                      child: EldPageHeader(
                        greeting: auth.user.displayName,
                        title: 'Driver Compliance',
                      ),
                    ),
                    if (overview != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      EldFadeIn(
                        delay: const Duration(milliseconds: 60),
                        child: GridView.count(
                          crossAxisCount: isWide ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: isWide ? 1.5 : 1.35,
                          children: [
                            EldMetricTile(
                              icon: Icons.groups_rounded,
                              label: 'Drivers',
                              value: '${overview.driverCount}',
                              accentColor: AppColors.navy,
                            ),
                            EldMetricTile(
                              icon: Icons.warning_amber_rounded,
                              label: 'Violations',
                              value: '${overview.violationCount}',
                              accentColor: AppColors.danger,
                            ),
                            EldMetricTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Uncertified',
                              value: '${overview.uncertifiedDriverCount}',
                              accentColor: AppColors.amber,
                            ),
                            EldMetricTile(
                              icon: Icons.notifications_active_rounded,
                              label: 'Push tokens',
                              value: '${overview.registeredPushTokens}',
                              accentColor: AppColors.teal,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Drivers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.drivers.isEmpty)
                      const EldEmptyState(
                        icon: Icons.person_off_rounded,
                        title: 'No drivers found',
                        subtitle: 'Assign drivers to this carrier to monitor compliance.',
                      )
                    else
                      ...state.drivers.asMap().entries.map(
                            (entry) => EldFadeIn(
                              delay: Duration(milliseconds: 40 * (entry.key % 6)),
                              child: _DriverTile(
                                driver: entry.value,
                                onTap: () => context.push(
                                  AppRoutes.fleetDriverPath(entry.value.id),
                                ),
                              ),
                            ),
                          ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, required this.onTap});

  final FleetDriverSnapshot driver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = driver.currentStatus?.displayName ?? 'No active log';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.navy.withValues(alpha: 0.12),
                  child: Text(
                    driver.displayName.isNotEmpty ? driver.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (driver.uncertifiedCount > 0 || driver.editedCount > 0)
                        Text(
                          '${driver.uncertifiedCount} uncertified · ${driver.editedCount} edited',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    EldStatusBadge(
                      label: driver.isInViolation ? 'Violation' : 'OK',
                      tone: driver.isInViolation ? EldBadgeTone.danger : EldBadgeTone.success,
                    ),
                    if (driver.hasPushToken)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.notifications_active_rounded, size: 16, color: AppColors.teal),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}