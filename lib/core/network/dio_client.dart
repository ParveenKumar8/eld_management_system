import 'package:dio/dio.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dio HTTP client with auth interceptors.
class DioClient {
  DioClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.secureKeyAccessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          AppLogger.error('HTTP ${error.response?.statusCode}', error);
          if (error.response?.statusCode == 401) {
            // Token refresh placeholder
            AppLogger.warning('Unauthorized - refresh token flow needed');
          }
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
  final FlutterSecureStorage _storage;

  Dio get dio => _dio;
}