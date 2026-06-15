import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
import 'package:eld_management_system/core/widgets/eld_primary_button.dart';
import 'package:eld_management_system/core/widgets/eld_status_badge.dart';
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
    final initial = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';

    final padding = Responsive.pagePadding(context);

    return Scaffold(
      body: EldScreen(
        bottom: false,
        child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            const EldPageHeader(title: 'My Profile'),
            EldFadeIn(
              child: Container(
              margin: EdgeInsets.symmetric(horizontal: padding.left),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                        ),
                        const SizedBox(height: 8),
                        EldStatusBadge(
                          label: user.role.value.replaceAll('_', ' ').toUpperCase(),
                          tone: EldBadgeTone.info,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding.left),
              child: Column(
                children: [
                  _InfoCard(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: user.role.value,
                  ),
                  if (user.licenseNumber != null)
                    _InfoCard(
                      icon: Icons.credit_card_rounded,
                      label: 'CDL Number',
                      value: user.licenseNumber!,
                    ),
                  if (user.carrierId != null)
                    _InfoCard(
                      icon: Icons.business_rounded,
                      label: 'Carrier ID',
                      value: user.carrierId!,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  EldPrimaryButton(
                    label: 'Sign Out',
                    icon: Icons.logout_rounded,
                    onPressed: () =>
                        context.read<AuthBloc>().add(const AuthSignOutRequested()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}