import 'dart:io';

import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/widgets/eld_glass_card.dart';
import 'package:eld_management_system/core/widgets/eld_gradient_background.dart';
import 'package:eld_management_system/core/widgets/eld_primary_button.dart';
import 'package:eld_management_system/core/widgets/eld_social_button.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_text_field.dart';
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
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in to manage your fleet HOS',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    EldFadeIn(
                      child: EldGlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EldTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'driver@fleet.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v != null && v.contains('@') ? null : 'Enter valid email',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            EldTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscure: _obscure,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) =>
                                  v != null && v.length >= 6 ? null : 'Min 6 characters',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            EldPrimaryButton(
                              label: 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                              loading: loading,
                              onPressed: loading ? null : _submit,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'or continue with',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            EldSocialButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata_rounded,
                              iconColor: Colors.red,
                              onPressed: loading
                                  ? null
                                  : () => context
                                      .read<AuthBloc>()
                                      .add(const AuthGoogleSignInRequested()),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            EldSocialButton(
                              label: 'Facebook',
                              icon: Icons.facebook_rounded,
                              iconColor: const Color(0xFF1877F2),
                              onPressed: loading
                                  ? null
                                  : () => context
                                      .read<AuthBloc>()
                                      .add(const AuthFacebookSignInRequested()),
                            ),
                            if (Platform.isIOS) ...[
                              const SizedBox(height: AppSpacing.sm),
                              EldSocialButton(
                                label: 'Apple',
                                icon: Icons.apple_rounded,
                                onPressed: loading
                                    ? null
                                    : () => context
                                        .read<AuthBloc>()
                                        .add(const AuthAppleSignInRequested()),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            Center(
                              child: TextButton(
                                onPressed: () => context.push(AppRoutes.signup),
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: 'New driver? ',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'Create account',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
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