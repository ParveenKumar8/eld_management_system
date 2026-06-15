import 'package:eld_management_system/core/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance'),
            subtitle: Text('Material 3 adaptive theme'),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('System'),
            value: AppThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light'),
            value: AppThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark'),
            value: AppThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          const Divider(),
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('ELD connection and HOS alerts'),
            trailing: Switch(value: true, onChanged: null),
          ),
          const ListTile(
            title: Text('Background Location'),
            subtitle: Text('Required for FMCSA compliant ELD'),
          ),
          const ListTile(
            title: Text('Crash Reporting'),
            subtitle: Text('Sentry integration placeholder'),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
