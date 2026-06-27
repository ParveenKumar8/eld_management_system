import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FleetPushPage extends ConsumerStatefulWidget {
  const FleetPushPage({super.key});

  @override
  ConsumerState<FleetPushPage> createState() => _FleetPushPageState();
}

class _FleetPushPageState extends ConsumerState<FleetPushPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _detailController = TextEditingController();
  var _alertType = 'complianceReminder';
  final Set<String> _selectedDriverIds = {};

  static const _alertTypes = <String, String>{
    'complianceReminder': 'Compliance reminder',
    'hosViolation': 'HOS violation',
    'fleetMessage': 'Fleet message',
    'documentRequired': 'Document required',
    'generic': 'General alert',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = ref.read(fleetCubitProvider);
      if (cubit.state.drivers.isEmpty) {
        cubit.loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')),
      );
      return;
    }

    final result = await ref.read(fleetCubitProvider).sendPush(
          type: _alertType,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          detail: _detailController.text.trim().isEmpty ? null : _detailController.text.trim(),
          driverIds: _selectedDriverIds.isEmpty ? null : _selectedDriverIds.toList(),
        );

    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push failed')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sent ${result.sent} · ${result.mode} (${result.deviceTokens} tokens)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = ref.watch(fleetCubitProvider);
    final padding = Responsive.pagePadding(context);

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: EldScreen(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 120),
            children: [
              const EldPageHeader(
                title: 'Fleet Alerts',
                greeting: 'Send FCM push to driver devices',
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _alertType,
                decoration: const InputDecoration(labelText: 'Alert type'),
                items: _alertTypes.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _alertType = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(labelText: 'Detail (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recipients',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave all unchecked to notify every driver in your carrier.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<FleetCubit, FleetState>(
                builder: (context, state) {
                  return Column(
                    children: state.drivers.map((driver) {
                      final selected = _selectedDriverIds.contains(driver.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedDriverIds.add(driver.id);
                            } else {
                              _selectedDriverIds.remove(driver.id);
                            }
                          });
                        },
                        title: Text(driver.displayName),
                        subtitle: Text(
                          driver.hasPushToken ? 'Push token registered' : 'No push token',
                        ),
                        secondary: Icon(
                          driver.hasPushToken
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: cubit.state.status == FleetStatus.sending ? null : _send,
                icon: cubit.state.status == FleetStatus.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Send push'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}