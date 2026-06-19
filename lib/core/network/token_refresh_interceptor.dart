import 'package:dio/dio.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';

/// Refreshes JWT access tokens on 401 and retries the original request once.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required SecureStorageService storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorageService _storage;
  Future<String?>? _refreshInFlight;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    try {
      final newToken = await _refreshAccessToken();
      if (newToken == null) {
        return handler.next(err);
      }

      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } catch (e, st) {
      AppLogger.warning('Token refresh retry failed', e, st);
      return handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() async {
    _refreshInFlight ??= _performRefresh();
    try {
      return await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _dio.post<dynamic>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );

    final envelope = parseApiMap(response.data);
    final data = envelope.data;
    if (data == null) return null;

    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null || refresh == null) return null;

    await _storage.saveTokens(accessToken: access, refreshToken: refresh);
    AppLogger.info('Access token refreshed');
    return access;
  }
}