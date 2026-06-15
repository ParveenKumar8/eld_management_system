import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: BlocConsumer<AuthBloc, AuthState>(
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
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 characters',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: loading
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            context.read<AuthBloc>().add(
                                  AuthSignUpEmailRequested(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                    displayName: _nameController.text.trim(),
                                  ),
                                );
                          },
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Create Account'),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}