import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
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
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(response.data!);
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
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'display_name': displayName,
        },
      );
      return _parseAuthResponse(response.data!);
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Registration failed');
    }
  }

  Future<({UserModel user, String accessToken, String refreshToken})> socialAuth({
    required String provider,
    required String idToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/social',
        data: {'provider': provider, 'id_token': idToken},
      );
      return _parseAuthResponse(response.data!);
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Social login failed');
    }
  }

  ({UserModel user, String accessToken, String refreshToken}) _parseAuthResponse(
    Map<String, dynamic> data,
  ) {
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