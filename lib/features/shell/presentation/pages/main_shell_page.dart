import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({required this.child, super.key});

  final Widget child;

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
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.bluetooth), label: 'ELD'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Logs'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}