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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELD Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            onPressed: () => context.read<EldBloc>().add(const EldScanStarted()),
          ),
        ],
      ),
      body: BlocConsumer<EldBloc, EldState>(
        listener: (context, state) {
          if (state is EldError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _ConnectionBanner(state: state),
              Expanded(
                child: state.devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            const Text('Tap scan to find ELD devices'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.read<EldBloc>().add(const EldScanStarted()),
                              icon: const Icon(Icons.search),
                              label: const Text('Scan Devices'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.devices.length,
                        itemBuilder: (_, i) => _DeviceTile(device: state.devices[i]),
                      ),
              ),
              if (state.connectionState == EldConnectionState.connected)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.tonal(
                    onPressed: () =>
                        context.read<EldBloc>().add(const EldDisconnectRequested()),
                    child: const Text('Disconnect'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state});
  final EldState state;

  @override
  Widget build(BuildContext context) {
    final connected = state.connectionState == EldConnectionState.connected;
    return MaterialBanner(
      content: Text('Status: ${state.connectionState.name}'),
      leading: Icon(
        connected ? Icons.check_circle : Icons.info,
        color: connected ? Colors.green : null,
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});
  final EldDevice device;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sensors),
      title: Text(device.name),
      subtitle: Text('RSSI: ${device.rssi} dBm'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.read<EldBloc>().add(EldConnectRequested(device.id)),
    );
  }
}