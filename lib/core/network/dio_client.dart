import 'package:dio/dio.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/network/auth_request_interceptor.dart';
import 'package:eld_management_system/core/network/token_refresh_interceptor.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';

/// Dio HTTP client with auth and token-refresh interceptors.
class DioClient {
  DioClient({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService.create(),
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(AuthRequestInterceptor(_storage));
    _dio.interceptors.add(
      TokenRefreshInterceptor(dio: _dio, storage: _storage),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          AppLogger.error('HTTP ${error.response?.statusCode}', error);
          return handler.next(error);
        },
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => AppLogger.debug(o.toString()),
      ),
    );
  }

  final Dio _dio;
  final SecureStorageService _storage;

  Dio get dio => _dio;
  SecureStorageService get storage => _storage;
}