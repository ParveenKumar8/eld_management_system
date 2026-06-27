import 'package:eld_management_system/core/widgets/eld_bottom_nav.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({required this.child, super.key});

  final Widget child;

  static const _driverItems = [
    EldNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home'),
    EldNavItem(icon: Icons.bluetooth_rounded, activeIcon: Icons.bluetooth_connected_rounded, label: 'ELD'),
    EldNavItem(icon: Icons.timeline_rounded, activeIcon: Icons.timeline_rounded, label: 'Logs'),
    EldNavItem(icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart_rounded, label: 'Reports'),
    EldNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  static const _fleetItems = [
    EldNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Fleet'),
    EldNavItem(icon: Icons.campaign_rounded, activeIcon: Icons.campaign_rounded, label: 'Alerts'),
    EldNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  bool _isFleetManager(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    return auth is AuthAuthenticated && auth.user.role.canManageFleet();
  }

  int _selectedIndex(BuildContext context, bool isFleet) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (isFleet) {
      if (loc.startsWith(AppRoutes.fleetPush)) return 1;
      if (loc.startsWith(AppRoutes.profile)) return 2;
      return 0;
    }
    if (loc.startsWith(AppRoutes.devices)) return 1;
    if (loc.startsWith(AppRoutes.logs)) return 2;
    if (loc.startsWith(AppRoutes.reports)) return 3;
    if (loc.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index, bool isFleet) {
    if (isFleet) {
      switch (index) {
        case 0:
          context.go(AppRoutes.dashboard);
        case 1:
          context.go(AppRoutes.fleetPush);
        case 2:
          context.go(AppRoutes.profile);
      }
      return;
    }

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
    final isFleet = _isFleetManager(context);
    final items = isFleet ? _fleetItems : _driverItems;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: EldBottomNav(
          items: items,
          selectedIndex: _selectedIndex(context, isFleet),
          onTap: (i) => _onTap(context, i, isFleet),
        ),
      ),
    );
  }
}