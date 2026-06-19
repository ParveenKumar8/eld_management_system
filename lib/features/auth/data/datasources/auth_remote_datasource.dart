import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/features/auth/data/models/user_model.dart';
import 'package:eld_management_system/features/auth/domain/entities/user_role.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({UserModel user, String accessToken, String refreshToken})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Login failed', code: '${e.response?.statusCode}');
    }
  }

  Future<({UserModel user, String accessToken, String refreshToken})> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'display_name': displayName,
        },
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Registration failed');
    }
  }

  Future<({UserModel user, String accessToken, String refreshToken})> socialAuth({
    required String provider,
    required String idToken,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/social',
        data: {'provider': provider, 'id_token': idToken},
        options: Options(extra: {'skipAuth': true}),
      );
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Social login failed');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get<dynamic>('/auth/me');
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw AuthException(envelope.error?.message ?? 'Profile fetch failed');
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Profile fetch failed', code: '${e.response?.statusCode}');
    }
  }

  Future<void> logout({required String refreshToken}) async {
    try {
      await _dio.post<dynamic>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Logout failed');
    }
  }

  ({UserModel user, String accessToken, String refreshToken}) _parseAuthResponse(dynamic raw) {
    final envelope = parseApiMap(raw);
    final data = envelope.data;
    if (data == null) {
      throw AuthException(envelope.error?.message ?? 'Authentication failed');
    }
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  /// Demo fallback when API unavailable (development only).
  ({UserModel user, String accessToken, String refreshToken}) demoAuth({
    required String email,
    String role = 'driver',
  }) {
    return (
      user: UserModel(
        id: 'demo-${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
        role: UserRole.fromString(role),
      ),
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
    );
  }
}