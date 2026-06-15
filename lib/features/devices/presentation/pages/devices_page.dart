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
import 'package:eld_management_system/features/devices/presentation/widgets/eld_ble_scan_progress.dart';
import 'package:eld_management_system/features/devices/presentation/widgets/eld_device_compatibility_badge.dart';
import 'package:eld_management_system/features/devices/presentation/widgets/eld_scan_no_results.dart';
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
      case EldConnectionState.verifying:
        return EldBadgeTone.warning;
      case EldConnectionState.disconnected:
        return EldBadgeTone.neutral;
    }
  }

  EldState _effectiveState(EldState state) => state is EldError ? (state.previous ?? state) : state;

  String _connectionLabel(EldState state) {
    if (state.isScanning) return DeviceStrings.connectionScanning;
    if (state.connectionState == EldConnectionState.verifying) {
      return DeviceStrings.connectionVerifying;
    }
    return state.connectionState.name;
  }

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
            final isScanning = viewState.isScanning && viewState.scanStartedAt != null;
            final canStartScan = !isScanning && !viewState.permissionsLoading;
            final showNoResults =
                viewState.scanPhase == EldScanPhase.completed && viewState.devices.isEmpty;
            final showInitialEmpty =
                viewState.scanPhase == EldScanPhase.idle && viewState.devices.isEmpty;

            return Column(
              children: [
                EldFadeIn(
                  child: EldPageHeader(
                    title: DeviceStrings.pageTitle,
                    trailing: IconButton(
                      onPressed: canStartScan
                          ? () => context.read<EldBloc>().add(const EldScanStarted())
                          : null,
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: canStartScan ? AppColors.accentGradient : null,
                          color: canStartScan ? null : AppColors.navy.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: !canStartScan
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navy),
                              )
                            : const Icon(Icons.radar_rounded, color: AppColors.navy, size: 20),
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
                    child: _ConnectionCard(
                      state: viewState,
                      tone: _tone(viewState.connectionState),
                      statusLabel: _connectionLabel(viewState),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: isScanning
                        ? EldBleScanProgress(
                            key: const ValueKey('scanning'),
                            startedAt: viewState.scanStartedAt!,
                            deviceCount: viewState.devices.length,
                            devices: viewState.devices,
                            onCancel: () =>
                                context.read<EldBloc>().add(const EldScanStopped()),
                          )
                        : showNoResults
                            ? EldScanNoResults(
                                key: const ValueKey('no-results'),
                                onScanAgain: () =>
                                    context.read<EldBloc>().add(const EldScanStarted()),
                              )
                            : showInitialEmpty
                                ? EldEmptyState(
                                    key: const ValueKey('initial-empty'),
                                    icon: Icons.sensors_rounded,
                                    title: DeviceStrings.emptyTitle,
                                    subtitle: DeviceStrings.emptySubtitle,
                                    actionLabel: DeviceStrings.startScan,
                                    onAction: canStartScan
                                        ? () =>
                                            context.read<EldBloc>().add(const EldScanStarted())
                                        : null,
                                  )
                                : _DeviceResults(
                                    key: ValueKey('results-${viewState.devices.length}'),
                                    devices: viewState.devices,
                                    columns: columns,
                                    padding: padding,
                                    verifyingDeviceId: viewState.verifyingDeviceId,
                                    onScanAgain: () =>
                                        context.read<EldBloc>().add(const EldScanStarted()),
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

class _DeviceResults extends StatelessWidget {
  const _DeviceResults({
    required this.devices,
    required this.columns,
    required this.padding,
    required this.onScanAgain,
    this.verifyingDeviceId,
    super.key,
  });

  final List<EldDevice> devices;
  final int columns;
  final EdgeInsets padding;
  final VoidCallback onScanAgain;
  final String? verifyingDeviceId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DeviceStrings.resultsHeader,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      DeviceStrings.resultsCount(devices.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DeviceStrings.resultsHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onScanAgain,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(DeviceStrings.scanAgain),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: Responsive.isDesktop(context) ? 2.8 : 2.2,
            ),
            itemCount: devices.length,
            itemBuilder: (_, i) => EldFadeIn(
              delay: Duration(milliseconds: 60 * i),
              child: _DeviceCard(
                device: devices[i],
                isVerifying: verifyingDeviceId == devices[i].id,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.state,
    required this.tone,
    required this.statusLabel,
  });

  final EldState state;
  final EldBadgeTone tone;
  final String statusLabel;

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
                : state.isScanning
                    ? Icons.bluetooth_searching_rounded
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
                Text(statusLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          EldStatusBadge(
            label: statusLabel,
            tone: tone,
            pulsing: tone == EldBadgeTone.success || state.isScanning,
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, this.isVerifying = false});
  final EldDevice device;
  final bool isVerifying;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: isVerifying
            ? null
            : () => context.read<EldBloc>().add(EldConnectRequested(device.id)),
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
                child: isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teal),
                      )
                    : const Icon(Icons.router_rounded, color: AppColors.teal),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Icon(
                isVerifying ? Icons.hourglass_top_rounded : Icons.arrow_forward_rounded,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}