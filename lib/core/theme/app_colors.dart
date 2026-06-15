import 'package:flutter/material.dart';

/// Brand palette — fleet-grade navy + amber accent.
abstract final class AppColors {
  static const Color navy = Color(0xFF0B1F3A);
  static const Color navyLight = Color(0xFF163A5F);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color teal = Color(0xFF14B8A6);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyLight, Color(0xFF1E4976)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [amber, Color(0xFFFBBF24)],
  );

  static const LinearGradient cardShine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
  );
}