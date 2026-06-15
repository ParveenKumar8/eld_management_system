import 'package:eld_management_system/core/utils/responsive.dart';
import 'package:flutter/material.dart';

/// Responsive grid: 1 col phone, 2 col tablet, 2+ col desktop.
class EldAdaptiveGrid extends StatelessWidget {
  const EldAdaptiveGrid({
    required this.children,
    this.spacing = 12,
    this.childAspectRatio,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    if (columns == 1) {
      return Column(
        children: children
            .map((c) => Padding(padding: EdgeInsets.only(bottom: spacing), child: c))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio ?? (Responsive.isDesktop(context) ? 1.8 : 1.5),
      children: children,
    );
  }
}