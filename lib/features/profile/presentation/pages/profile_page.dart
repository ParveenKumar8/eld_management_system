import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.displayName, style: Theme.of(context).textTheme.headlineSmall),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _InfoTile('Role', user.role.value),
          if (user.licenseNumber != null)
            _InfoTile('CDL', user.licenseNumber!),
          if (user.carrierId != null)
            _InfoTile('Carrier ID', user.carrierId!),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}