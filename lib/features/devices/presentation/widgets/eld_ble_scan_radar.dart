import 'dart:math' as math;

import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Animated radar sweep used while BLE scanning is in progress.
class EldBleScanRadar extends StatefulWidget {
  const EldBleScanRadar({this.size = 220, super.key});

  final double size;

  @override
  State<EldBleScanRadar> createState() => _EldBleScanRadarState();
}

class _EldBleScanRadarState extends State<EldBleScanRadar> with TickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_sweepController, _pulseController]),
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              sweepAngle: _sweepController.value * 2 * math.pi,
              pulse: _pulseController.value,
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.bluetooth_searching_rounded, color: AppColors.navy, size: 34),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.sweepAngle, required this.pulse});

  final double sweepAngle;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 1; i <= 3; i++) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.teal.withValues(alpha: 0.12 + (0.08 * i));
      canvas.drawCircle(center, radius * (i / 3), ringPaint);
    }

    final pulseRadius = radius * (0.35 + pulse * 0.55);
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.teal.withValues(alpha: (1 - pulse) * 0.55);
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + math.pi / 3,
        colors: [
          AppColors.teal.withValues(alpha: 0.0),
          AppColors.teal.withValues(alpha: 0.35),
          AppColors.amber.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        colors: [
          AppColors.teal.withValues(alpha: 0.0),
          AppColors.teal,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    final lineEnd = Offset(
      center.dx + math.cos(sweepAngle) * radius,
      center.dy + math.sin(sweepAngle) * radius,
    );
    canvas.drawLine(center, lineEnd, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle || oldDelegate.pulse != pulse;
}