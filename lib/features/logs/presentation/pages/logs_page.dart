import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();

    final cubit = ref.watch(hosCubitProvider(auth.user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_inspectionMode ? 'Inspection Mode' : 'HOS Logs'),
        actions: [
          IconButton(
            icon: Icon(_inspectionMode ? Icons.visibility_off : Icons.policy),
            onPressed: () => setState(() => _inspectionMode = !_inspectionMode),
            tooltip: 'Inspection mode',
          ),
        ],
      ),
      body: BlocBuilder<HosCubit, HosState>(
        bloc: cubit,
        builder: (context, state) {
          if (state.status == HosStatus.loading && state.records.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.records.isEmpty) {
            return const Center(child: Text('No log entries yet'));
          }
          final fmt = DateFormat('MMM d, HH:mm');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.records.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = state.records[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(r.status.code),
                ),
                title: Text(r.status.displayName),
                subtitle: Text(
                  '${fmt.format(r.startTime.toLocal())}'
                  '${r.endTime != null ? ' – ${fmt.format(r.endTime!.toLocal())}' : ' (active)'}'
                  '${r.annotation != null ? '\n${r.annotation}' : ''}',
                ),
                trailing: r.isEdited ? const Icon(Icons.edit, size: 16) : null,
              );
            },
          );
        },
      ),
    );
  }
}