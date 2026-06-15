import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    // Auth check runs once in main(); no API call — local cache only.
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'ELD Management',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'FMCSA Compliant Hours of Service',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final label = switch (state) {
                  AuthInitial() || AuthLoading() => 'Checking local session…',
                  AuthUnauthenticated() => 'Redirecting to sign in…',
                  AuthAuthenticated() => 'Opening dashboard…',
                  AuthError(:final message) => message,
                };
                return Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}
