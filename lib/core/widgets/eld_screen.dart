import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:flutter/material.dart';

/// SafeArea + responsive max-width wrapper for all screens.
class EldScreen extends StatelessWidget {
  const EldScreen({
    required this.child,
    this.bottom = true,
    this.top = true,
    this.centerContent = true,
    super.key,
  });

  final Widget child;
  final bool bottom;
  final bool top;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (centerContent && Responsive.isTabletOrLarger(context)) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: content,
        ),
      );
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      child: content,
    );
  }
}