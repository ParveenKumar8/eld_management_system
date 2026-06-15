import 'package:flutter/material.dart';

/// Breakpoints for phone / tablet / desktop layouts.
abstract final class Responsive {
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double maxContentWidth = 1100;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static bool isPhone(BuildContext context) => width(context) < tabletBreakpoint;
  static bool isTablet(BuildContext context) =>
      width(context) >= tabletBreakpoint && width(context) < desktopBreakpoint;
  static bool isDesktop(BuildContext context) => width(context) >= desktopBreakpoint;
  static bool isTabletOrLarger(BuildContext context) => width(context) >= tabletBreakpoint;

  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  static double mapHeight(BuildContext context) {
    if (isDesktop(context)) return 360;
    if (isTablet(context)) return 320;
    return 220;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
}