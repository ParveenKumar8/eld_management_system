import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(
    id: '1',
    email: 'driver@test.com',
    displayName: 'Driver',
    role: UserRole.driver,
  );

  group('resolveAuthRedirect', () {
    test('stays on splash while loading', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthLoading(),
          matchedLocation: AppRoutes.splash,
        ),
        isNull,
      );
    });

    test('redirects from splash to login when unauthenticated', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthUnauthenticated(),
          matchedLocation: AppRoutes.splash,
        ),
        AppRoutes.login,
      );
    });

    test('redirects from splash to login on auth error', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthError('Cache read failed'),
          matchedLocation: AppRoutes.splash,
        ),
        AppRoutes.login,
      );
    });

    test('redirects authenticated user from splash to dashboard', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthAuthenticated(user),
          matchedLocation: AppRoutes.splash,
        ),
        AppRoutes.dashboard,
      );
    });

    test('allows login page when unauthenticated', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthUnauthenticated(),
          matchedLocation: AppRoutes.login,
        ),
        isNull,
      );
    });
  });
}