import 'package:eld_management_system/core/strings/device_strings.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_empty_state.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_permission_gate.dart';
import 'package:eld_management_system/core/widgets/eld_primary_button.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_status_badge.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  @override
  void initState() {
    super.initState();
    context.read<EldBloc>().add(const EldPermissionsRequested());
  }

  EldBadgeTone _tone(EldConnectionState s) {
    switch (s) {
      case EldConnectionState.connected:
        return EldBadgeTone.success;
      case EldConnectionState.error:
        return EldBadgeTone.danger;
      case EldConnectionState.connecting:
      case EldConnectionState.reconnecting:
      case EldConnectionState.scanning:
        return EldBadgeTone.warning;
      case EldConnectionState.disconnected:
        return EldBadgeTone.neutral;
    }
  }

  EldState _effectiveState(EldState state) => state is EldError ? (state.previous ?? state) : state;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);
    final columns = Responsive.isTabletOrLarger(context) ? 2 : 1;

    return Scaffold(
      body: EldScreen(
        bottom: false,
        child: BlocConsumer<EldBloc, EldState>(
          listener: (context, state) {
            if (state is EldError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final viewState = _effectiveState(state);

            return Column(
              children: [
                EldFadeIn(
                  child: EldPageHeader(
                    title: DeviceStrings.pageTitle,
                    trailing: IconButton(
                      onPressed: () => context.read<EldBloc>().add(const EldScanStarted()),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.radar_rounded, color: AppColors.navy, size: 20),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding.left),
                  child: EldFadeIn(
                    delay: const Duration(milliseconds: 40),
                    child: EldPermissionGate(
                      statuses: viewState.permissionStatuses,
                      isLoading: viewState.permissionsLoading,
                      onGrantAll: () =>
                          context.read<EldBloc>().add(const EldPermissionsRequested()),
                      onRetry: () =>
                          context.read<EldBloc>().add(const EldPermissionsRefreshRequested()),
                      onOpenSettings: () =>
                          context.read<EldBloc>().add(const EldOpenSettingsRequested()),
                      onRequestItem: (kind) =>
                          context.read<EldBloc>().add(EldPermissionItemRequested(kind)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding.left),
                  child: EldFadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: _ConnectionCard(state: viewState, tone: _tone(viewState.connectionState)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: viewState.devices.isEmpty
                      ? EldEmptyState(
                          icon: Icons.sensors_rounded,
                          title: DeviceStrings.emptyTitle,
                          subtitle: DeviceStrings.emptySubtitle,
                          actionLabel: DeviceStrings.startScan,
                          onAction: () =>
                              context.read<EldBloc>().add(const EldScanStarted()),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 120),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: Responsive.isDesktop(context) ? 2.8 : 2.2,
                          ),
                          itemCount: viewState.devices.length,
                          itemBuilder: (_, i) => EldFadeIn(
                            delay: Duration(milliseconds: 60 * i),
                            child: _DeviceCard(device: viewState.devices[i]),
                          ),
                        ),
                ),
                if (viewState.connectionState == EldConnectionState.connected)
                  Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 100),
                    child: EldPrimaryButton(
                      label: DeviceStrings.disconnect,
                      icon: Icons.link_off_rounded,
                      onPressed: () =>
                          context.read<EldBloc>().add(const EldDisconnectRequested()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.state, required this.tone});
  final EldState state;
  final EldBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            state.connectionState == EldConnectionState.connected
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_rounded,
            color: AppColors.navy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DeviceStrings.connectionStatusTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(state.connectionState.name, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          EldStatusBadge(label: state.connectionState.name, tone: tone, pulsing: tone == EldBadgeTone.success),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final EldDevice device;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => context.read<EldBloc>().add(EldConnectRequested(device.id)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.router_rounded, color: AppColors.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DeviceStrings.signalDetail(device.rssi),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}