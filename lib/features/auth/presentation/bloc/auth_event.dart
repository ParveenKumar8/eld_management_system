part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthSignInEmailRequested extends AuthEvent {
  const AuthSignInEmailRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpEmailRequested extends AuthEvent {
  const AuthSignUpEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
  final String email;
  final String password;
  final String displayName;
  @override
  List<Object?> get props => [email, password, displayName];
}

final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

final class AuthFacebookSignInRequested extends AuthEvent {
  const AuthFacebookSignInRequested();
}

final class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested({
    this.displayName,
    this.licenseNumber,
  });

  final String? displayName;
  final String? licenseNumber;

  @override
  List<Object?> get props => [displayName, licenseNumber];
}