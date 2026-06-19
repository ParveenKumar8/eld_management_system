import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  ResultFuture<User> signInWithEmail({required String email, required String password});
  ResultFuture<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  ResultFuture<User> signInWithGoogle();
  ResultFuture<User> signInWithFacebook();
  ResultFuture<User> signInWithApple();
  ResultFuture<void> signOut();
  ResultFuture<User?> getCurrentUser();
  ResultFuture<User> updateProfile({
    String? displayName,
    String? licenseNumber,
  });
  Future<void> syncProfile();
  Stream<User?> watchAuthState();
}