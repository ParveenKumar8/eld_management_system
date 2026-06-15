import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum EldBadgeTone { success, warning, danger, info, neutral }

class EldStatusBadge extends StatelessWidget {
  const EldStatusBadge({
    required this.label,
    this.tone = EldBadgeTone.neutral,
    this.pulsing = false,
    super.key,
  });

  final String label;
  final EldBadgeTone tone;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = _colors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: dot, pulsing: pulsing),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _colors(EldBadgeTone tone) {
    switch (tone) {
      case EldBadgeTone.success:
        return (const Color(0xFFDCFCE7), const Color(0xFF166534), AppColors.success);
      case EldBadgeTone.warning:
        return (AppColors.amberSoft, const Color(0xFF92400E), AppColors.amber);
      case EldBadgeTone.danger:
        return (const Color(0xFFFEE2E2), const Color(0xFF991B1B), AppColors.danger);
      case EldBadgeTone.info:
        return (const Color(0xFFE0F2FE), const Color(0xFF075985), AppColors.teal);
      case EldBadgeTone.neutral:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569), const Color(0xFF94A3B8));
    }
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulsing});
  final Color color;
  final bool pulsing;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = widget.pulsing ? 0.7 + (_controller.value * 0.3) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}