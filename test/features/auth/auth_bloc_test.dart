import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthBloc bloc;

  const testUser = User(
    id: '1',
    email: 'driver@fleet.com',
    displayName: 'Test Driver',
    role: UserRole.driver,
  );

  setUp(() {
    repository = MockAuthRepository();
    bloc = AuthBloc(repository);
  });

  blocTest<AuthBloc, AuthState>(
    'emits authenticated on successful email login',
    build: () {
      when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(testUser));
      return bloc;
    },
    act: (b) => b.add(
      const AuthSignInEmailRequested(
        email: 'driver@fleet.com',
        password: 'password123',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthAuthenticated(testUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits error on failed login',
    build: () {
      when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(AuthFailure('Invalid credentials')));
      return bloc;
    },
    act: (b) => b.add(
      const AuthSignInEmailRequested(email: 'x@y.com', password: 'bad'),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthError('Invalid credentials'),
    ],
  );
}