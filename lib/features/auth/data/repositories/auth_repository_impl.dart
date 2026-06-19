import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:eld_management_system/features/auth/data/models/user_model.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_pending_store.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_sync_service.dart';
import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    ProfileSyncService? profileSync,
    ProfilePendingStore? profilePending,
    GoogleSignIn? googleSignIn,
  })  : _remote = remote,
        _local = local,
        _profileSync = profileSync,
        _profilePending = profilePending,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final ProfileSyncService? _profileSync;
  final ProfilePendingStore? _profilePending;
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
        fallbackEmail: email,
      );
      await _persistSession(result);
      await syncProfile();
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
        fallbackEmail: email,
      );
      await _persistSession(result);
      await syncProfile();
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
        fallbackEmail: account.email,
      );
      await _persistSession(result);
      await syncProfile();
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
        fallbackEmail: 'fb_user@demo.com',
      );
      await _persistSession(auth);
      await syncProfile();
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
        fallbackEmail: email,
      );
      await _persistSession(auth);
      await syncProfile();
      return Right(_currentUser!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> signOut() async {
    final refresh = await _local.getRefreshToken();
    if (refresh != null && !refresh.startsWith('demo_')) {
      try {
        await _remote.logout(refreshToken: refresh);
      } catch (e) {
        AppLogger.warning('Remote logout failed', e);
      }
    }
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _profilePending?.clear();
    await _local.clearSession();
    _currentUser = null;
    return const Right(null);
  }

  @override
  ResultFuture<User?> getCurrentUser() async {
    if (_currentUser != null) return Right(_currentUser);

    final cached = await _local.getCachedUser();
    if (cached == null) {
      _currentUser = null;
      return const Right(null);
    }

    final access = await _local.getAccessToken();
    if (AppConstants.useDemoAuth || access?.startsWith('demo_') == true) {
      _currentUser = cached.toEntity();
      return Right(_currentUser);
    }

    try {
      final synced = await _profileSync?.syncAll();
      if (synced != null) {
        _currentUser = synced.toEntity();
        return Right(_currentUser);
      }

      final remoteUser = await _remote.getMe();
      await _local.updateCachedUser(remoteUser);
      _currentUser = remoteUser.toEntity();
      return Right(_currentUser);
    } on AuthException {
      await _local.clearSession();
      _currentUser = null;
      return const Right(null);
    }
  }

  @override
  ResultFuture<User> updateProfile({
    String? displayName,
    String? licenseNumber,
  }) async {
    try {
      final cached = await _local.getCachedUser();
      if (cached == null) {
        return const Left(AuthFailure('Not signed in'));
      }

      final updated = UserModel(
        id: cached.id,
        email: cached.email,
        displayName: displayName ?? cached.displayName,
        role: cached.role,
        licenseNumber: licenseNumber ?? cached.licenseNumber,
        carrierId: cached.carrierId,
      );
      await _local.updateCachedUser(updated);
      _currentUser = updated.toEntity();

      await _profilePending?.save(
        displayName: displayName,
        licenseNumber: licenseNumber,
      );

      if (_profileSync != null && await _profileSync.canSync()) {
        await _profileSync.pushPending();
        final fresh = await _profileSync.pullFromServer();
        if (fresh != null) {
          _currentUser = fresh.toEntity();
        }
      }

      return Right(_currentUser!);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> syncProfile() async {
    final profile = await _profileSync?.syncAll();
    if (profile != null) {
      _currentUser = profile.toEntity();
    }
  }

  @override
  Stream<User?> watchAuthState() async* {
    yield _currentUser;
    final cached = await _local.getCachedUser();
    _currentUser = cached?.toEntity();
    yield _currentUser;
  }

  Future<void> _persistSession(
    ({UserModel user, String accessToken, String refreshToken}) result,
  ) async {
    await _local.cacheSession(
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    _currentUser = result.user.toEntity();
  }

  Future<({UserModel user, String accessToken, String refreshToken})> _tryRemote(
    Future<({UserModel user, String accessToken, String refreshToken})> Function() remote, {
    required String fallbackEmail,
  }) async {
    if (AppConstants.useDemoAuth) {
      try {
        return await remote();
      } on AuthException {
        AppLogger.warning('Remote auth unavailable, using demo fallback');
        return _remote.demoAuth(email: fallbackEmail);
      }
    }
    return remote();
  }
}