import 'package:dio/dio.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';

/// Attaches bearer token to outgoing API requests.
class AuthRequestInterceptor extends Interceptor {
  AuthRequestInterceptor(this._storage);

  final SecureStorageService _storage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}