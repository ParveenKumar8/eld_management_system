import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_glass_card.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_gradient_background.dart';
import 'package:eld_management_system/core/widgets/eld_primary_button.dart';
import 'package:eld_management_system/core/widgets/eld_text_field.dart';
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
      body: EldGradientBackground(
        child: EldScreen(
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                    Text(
                      'Join the fleet',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create your driver account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    EldFadeIn(child: EldGlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            EldTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            EldTextField(
                              controller: _emailController,
                              label: 'Email',
                              prefixIcon: Icons.email_outlined,
                              validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            EldTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscure: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 characters',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            EldPrimaryButton(
                              label: 'Create Account',
                              icon: Icons.check_rounded,
                              loading: loading,
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
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}