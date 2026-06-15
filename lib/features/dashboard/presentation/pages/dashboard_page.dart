import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/presentation/cubit/hos_cubit.dart';
import 'package:eld_management_system/features/hos/presentation/widgets/duty_status_selector.dart';
import 'package:eld_management_system/features/hos/presentation/widgets/hos_summary_card.dart';
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
      return const Center(child: CircularProgressIndicator());
    }
    final driverId = authState.user.id;
    final hosCubit = ref.watch(hosCubitProvider(driverId));

    return BlocProvider.value(
      value: hosCubit,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => hosCubit.load(driverId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome, ${authState.user.displayName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              BlocBuilder<EldBloc, EldState>(
                builder: (context, eldState) {
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        eldState.connectionState == EldConnectionState.connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: eldState.connectionState == EldConnectionState.connected
                            ? Colors.green
                            : null,
                      ),
                      title: const Text('ELD Connection'),
                      subtitle: Text(_connectionLabel(eldState.connectionState)),
                      trailing: eldState.latestData != null
                          ? Text('${eldState.latestData!.speedMph.toStringAsFixed(0)} mph')
                          : null,
                      onTap: () => context.go(AppRoutes.devices),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<HosCubit, HosState>(
                bloc: hosCubit,
                builder: (context, hosState) {
                  if (hosState.status == HosStatus.loading &&
                      hosState.summary == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (hosState.summary != null) {
                    return HosSummaryCard(summary: hosState.summary!);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              Text('Change Duty Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DutyStatusSelector(
                onSelected: (status) async {
                  final annotation = status == DutyStatus.offDuty
                      ? await _promptAnnotation(context)
                      : null;
                  if (!context.mounted) return;
                  await hosCubit.changeStatus(
                    driverId: driverId,
                    status: status,
                    annotation: annotation,
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<EldBloc, EldState>(
                builder: (context, eld) {
                  if (eld.latestData?.latitude == null) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.map),
                        title: Text('Location'),
                        subtitle: Text('Waiting for ELD GPS data...'),
                      ),
                    );
                  }
                  final d = eld.latestData!;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.map),
                      title: const Text('Live Location'),
                      subtitle: Text(
                        '${d.latitude!.toStringAsFixed(5)}, ${d.longitude!.toStringAsFixed(5)}',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _connectionLabel(EldConnectionState state) {
    switch (state) {
      case EldConnectionState.connected:
        return 'Connected';
      case EldConnectionState.connecting:
        return 'Connecting...';
      case EldConnectionState.scanning:
        return 'Scanning...';
      case EldConnectionState.reconnecting:
        return 'Reconnecting...';
      case EldConnectionState.error:
        return 'Connection error';
      case EldConnectionState.disconnected:
        return 'Not connected';
    }
  }

  Future<String?> _promptAnnotation(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annotation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason for status change (FMCSA)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}