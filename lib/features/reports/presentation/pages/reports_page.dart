import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Compliance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('7/8 Day Logs'),
              subtitle: const Text('View rolling cycle per FMCSA 395'),
              onTap: () {
                ref.read(hosCubitProvider(auth.user.id)).load(auth.user.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading 8-day log summary')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Edit Requests'),
              subtitle: const Text('Certified edits with driver annotation'),
              onTap: () => _showEditInfo(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Export for Inspection'),
              subtitle: const Text('Email, web service, or Bluetooth transfer'),
              onTap: () => _export(context, ref, auth.user.id),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Malfunction & Diagnostic Events'),
              subtitle: const Text('FMCSA required event logging'),
              onTap: () => _logMalfunction(context, ref, auth.user.id),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Certification'),
        content: const Text(
          'Log edits require driver certification and retain original '
          'records per 49 CFR 395.30. Fleet managers cannot certify on behalf of drivers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String driverId) async {
    final json = await ref.read(hosCubitProvider(driverId)).exportLogs(driverId);
    if (!context.mounted) return;
    if (json == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ELD output copied to clipboard')),
    );
  }

  Future<void> _logMalfunction(
    BuildContext context,
    WidgetRef ref,
    String driverId,
  ) async {
    // Placeholder - would call hos repository logMalfunction
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Malfunction logged (demo)')),
    );
  }
}