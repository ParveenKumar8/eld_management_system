import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/auth/presentation/pages/login_page.dart';
import 'package:eld_management_system/features/auth/presentation/pages/signup_page.dart';
import 'package:eld_management_system/features/auth/presentation/pages/splash_page.dart';
import 'package:eld_management_system/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:eld_management_system/features/devices/presentation/pages/devices_page.dart';
import 'package:eld_management_system/features/logs/presentation/pages/logs_page.dart';
import 'package:eld_management_system/features/profile/presentation/pages/profile_page.dart';
import 'package:eld_management_system/features/reports/presentation/pages/reports_page.dart';
import 'package:eld_management_system/features/settings/presentation/pages/settings_page.dart';
import 'package:eld_management_system/features/shell/presentation/pages/main_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const devices = '/devices';
  static const logs = '/logs';
  static const reports = '/reports';
  static const profile = '/profile';
  static const settings = '/settings';
}

/// Pure redirect logic — testable without GoRouter.
String? resolveAuthRedirect({
  required AuthState authState,
  required String matchedLocation,
}) {
  final onSplash = matchedLocation == AppRoutes.splash;
  final onAuth = matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.signup;

  // Still checking local session — stay on splash only.
  if (authState is AuthInitial || authState is AuthLoading) {
    return onSplash ? null : AppRoutes.splash;
  }

  // No session (or auth error) — leave splash for login.
  if (authState is AuthUnauthenticated || authState is AuthError) {
    return onAuth ? null : AppRoutes.login;
  }

  if (authState is AuthAuthenticated) {
    if (onAuth || onSplash) return AppRoutes.dashboard;
  }

  return null;
}

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshListenable(authBloc),
    redirect: (context, state) => resolveAuthRedirect(
      authState: authBloc.state,
      matchedLocation: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.devices,
            builder: (_, __) => const DevicesPage(),
          ),
          GoRoute(
            path: AppRoutes.logs,
            builder: (_, __) => const LogsPage(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, __) => const ReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._bloc) {
    _subscription = _bloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc _bloc;
  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}