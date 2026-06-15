import 'package:bloc/bloc.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthSignInEmailRequested>(_onSignInEmail);
    on<AuthSignUpEmailRequested>(_onSignUpEmail);
    on<AuthGoogleSignInRequested>(_onGoogle);
    on<AuthFacebookSignInRequested>(_onFacebook);
    on<AuthAppleSignInRequested>(_onApple);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repository;

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    AppLogger.info('AuthCheck: reading cached session (no network call)');
    final result = await _repository.getCurrentUser();
    result.fold(
      (f) {
        AppLogger.warning('AuthCheck failed: ${f.message}');
        emit(AuthError(f.message));
      },
      (user) {
        if (user != null) {
          AppLogger.info('AuthCheck: restored session for ${user.email}');
          emit(AuthAuthenticated(user));
        } else {
          AppLogger.info('AuthCheck: no cached session — login required');
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onSignInEmail(
    AuthSignInEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (f) => emit(AuthError(f.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignUpEmail(
    AuthSignUpEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.signUpWithEmail(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    result.fold(
      (f) => emit(AuthError(f.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onGoogle(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithGoogle();
    result.fold(
      (f) => emit(AuthError(f.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onFacebook(AuthFacebookSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithFacebook();
    result.fold(
      (f) => emit(AuthError(f.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onApple(AuthAppleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithApple();
    result.fold(
      (f) => emit(AuthError(f.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }
}