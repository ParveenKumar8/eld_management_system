import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Full-screen gradient backdrop for auth & splash screens.
class EldGradientBackground extends StatelessWidget {
  const EldGradientBackground({
    required this.child,
    this.showOrbs = true,
    super.key,
  });

  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.heroGradient)),
        if (showOrbs) ...[
          Positioned(
            top: -80,
            right: -60,
            child: _Orb(size: 220, color: AppColors.amber.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: 120,
            left: -100,
            child: _Orb(size: 280, color: AppColors.teal.withValues(alpha: 0.12)),
          ),
        ],
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}