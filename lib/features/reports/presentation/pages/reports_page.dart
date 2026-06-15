import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:eld_management_system/core/widgets/eld_fade_in.dart';
import 'package:eld_management_system/core/widgets/eld_page_header.dart';
import 'package:eld_management_system/core/widgets/eld_screen.dart';
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

    final padding = Responsive.pagePadding(context);
    final isWide = Responsive.isTabletOrLarger(context);

    final cards = [
          _ReportCard(
            icon: Icons.calendar_view_week_rounded,
            color: AppColors.teal,
            title: '7/8 Day Logs',
            subtitle: 'Rolling cycle per 49 CFR 395',
            onTap: () {
              ref.read(hosCubitProvider(auth.user.id)).load(auth.user.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loading 8-day log summary')),
              );
            },
          ),
          _ReportCard(
            icon: Icons.edit_note_rounded,
            color: AppColors.amber,
            title: 'Edit Requests',
            subtitle: 'Certified edits with driver annotation',
            onTap: () => _showEditInfo(context),
          ),
          _ReportCard(
            icon: Icons.upload_file_rounded,
            color: AppColors.navy,
            title: 'Export for Inspection',
            subtitle: 'Email, web service, or Bluetooth transfer',
            onTap: () => _export(context, ref, auth.user.id),
          ),
          _ReportCard(
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            title: 'Malfunction Events',
            subtitle: 'FMCSA diagnostic & malfunction logging',
            onTap: () => _logMalfunction(context),
          ),
    ];

    return Scaffold(
      body: EldScreen(
        bottom: false,
        child: ListView(
        padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 120),
        children: [
          const EldPageHeader(
            title: 'Compliance',
            greeting: 'FMCSA reports & exports',
          ),
          if (isWide)
            ...List.generate((cards.length / 2).ceil(), (row) {
              final left = row * 2;
              final right = left + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: EldFadeIn(delay: Duration(milliseconds: row * 80), child: cards[left])),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: right < cards.length
                          ? EldFadeIn(delay: Duration(milliseconds: row * 80 + 40), child: cards[right])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            })
          else
            ...cards.asMap().entries.map(
                  (e) => EldFadeIn(
                    delay: Duration(milliseconds: e.key * 60),
                    child: e.value,
                  ),
                ),
        ],
      ),
      ),
    );
  }

  void _showEditInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Certification',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Log edits require driver certification and retain original '
              'records per 49 CFR 395.30. Fleet managers cannot certify on behalf of drivers.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
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
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ELD output copied to clipboard')),
    );
  }

  void _logMalfunction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Malfunction logged (demo)')),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}