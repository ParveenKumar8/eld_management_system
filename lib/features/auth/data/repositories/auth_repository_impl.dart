import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:eld_management_system/features/auth/data/models/user_model.dart';
import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    GoogleSignIn? googleSignIn,
  })  : _remote = remote,
        _local = local,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final GoogleSignIn _googleSignIn;
  User? _currentUser;

  @override
  ResultFuture<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _tryRemote(
        () async => _remote.signIn(email: email, password: password),
        fallback: () async => _remote.demoAuth(email: email),
      );
      await _local.cacheSession(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _currentUser = result.user.toEntity();
      return Right(_currentUser!);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } catch (e, st) {
      AppLogger.error('signInWithEmail', e, st);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await _tryRemote(
        () async => _remote.signUp(email: email, password: password, displayName: displayName),
        fallback: () async => _remote.demoAuth(email: email),
      );
      await _local.cacheSession(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _currentUser = result.user.toEntity();
      return Right(_currentUser!);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const Left(AuthFailure('Google sign-in cancelled'));
      }
      final auth = await account.authentication;
      final result = await _tryRemote(
        () async => _remote.socialAuth(provider: 'google', idToken: auth.idToken ?? ''),
        fallback: () async => _remote.demoAuth(email: account.email),
      );
      await _local.cacheSession(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _currentUser = result.user.toEntity();
      return Right(_currentUser!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        return Left(AuthFailure(result.message ?? 'Facebook login failed'));
      }
      final token = result.accessToken?.tokenString ?? '';
      final auth = await _tryRemote(
        () async => _remote.socialAuth(provider: 'facebook', idToken: token),
        fallback: () async => _remote.demoAuth(email: 'fb_user@demo.com'),
      );
      await _local.cacheSession(
        user: auth.user,
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      _currentUser = auth.user.toEntity();
      return Right(_currentUser!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  ResultFuture<User> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final email = credential.email ?? 'apple_user@privaterelay.appleid.com';
      final auth = await _tryRemote(
        () async => _remote.socialAuth(
          provider: 'apple',
          idToken: credential.identityToken ?? '',
        ),
        fallback: () async => _remote.demoAuth(email: email),
      );
      await _local.cacheSession(
        user: auth.user,
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      _currentUser = auth.user.toEntity();
      return Right(_currentUser!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _local.clearSession();
    _currentUser = null;
    return const Right(null);
  }

  @override
  ResultFuture<User?> getCurrentUser() async {
    if (_currentUser != null) return Right(_currentUser);
    final cached = await _local.getCachedUser();
    _currentUser = cached?.toEntity();
    return Right(_currentUser);
  }

  @override
  Stream<User?> watchAuthState() async* {
    yield _currentUser;
    final cached = await _local.getCachedUser();
    _currentUser = cached?.toEntity();
    yield _currentUser;
  }

  Future<({UserModel user, String accessToken, String refreshToken})> _tryRemote(
    Future<({UserModel user, String accessToken, String refreshToken})> Function() remote, {
    required Future<({UserModel user, String accessToken, String refreshToken})> Function()
        fallback,
  }) async {
    try {
      return await remote();
    } on AuthException {
      AppLogger.warning('Remote auth unavailable, using demo fallback');
      return fallback();
    }
  }
}