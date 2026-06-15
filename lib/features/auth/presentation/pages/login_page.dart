import 'dart:io';

import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthSignInEmailRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Sign In',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          v != null && v.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Min 6 characters',
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 24),
                    const Row(children: [Expanded(child: Divider()), Text(' OR '), Expanded(child: Divider())]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () => context.read<AuthBloc>().add(const AuthGoogleSignInRequested()),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () => context.read<AuthBloc>().add(const AuthFacebookSignInRequested()),
                      icon: const Icon(Icons.facebook),
                      label: const Text('Continue with Facebook'),
                    ),
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: loading
                            ? null
                            : () => context.read<AuthBloc>().add(const AuthAppleSignInRequested()),
                        icon: const Icon(Icons.apple),
                        label: const Text('Continue with Apple'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.signup),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}