import 'package:eld_management_system/core/widgets/eld_bottom_nav.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({required this.child, super.key});

  final Widget child;

  static const _items = [
    EldNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home'),
    EldNavItem(icon: Icons.bluetooth_rounded, activeIcon: Icons.bluetooth_connected_rounded, label: 'ELD'),
    EldNavItem(icon: Icons.timeline_rounded, activeIcon: Icons.timeline_rounded, label: 'Logs'),
    EldNavItem(icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart_rounded, label: 'Reports'),
    EldNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith(AppRoutes.devices)) return 1;
    if (loc.startsWith(AppRoutes.logs)) return 2;
    if (loc.startsWith(AppRoutes.reports)) return 3;
    if (loc.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.devices);
      case 2:
        context.go(AppRoutes.logs);
      case 3:
        context.go(AppRoutes.reports);
      case 4:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: EldBottomNav(
          items: _items,
          selectedIndex: _selectedIndex(context),
          onTap: (i) => _onTap(context, i),
        ),
      ),
    );
  }
}