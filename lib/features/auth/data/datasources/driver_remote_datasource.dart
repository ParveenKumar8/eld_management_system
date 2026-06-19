import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/features/auth/data/models/user_model.dart';

class DriverRemoteDataSource {
  DriverRemoteDataSource(this._dio);
  final Dio _dio;

  Future<UserModel> getDriverProfile() async {
    try {
      final response = await _dio.get<dynamic>('/drivers/me');
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Driver profile fetch failed');
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Driver profile fetch failed',
        code: '${e.response?.statusCode}',
      );
    }
  }

  Future<UserModel> updateDriverProfile({
    String? displayName,
    String? licenseNumber,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/drivers/me',
        data: {
          if (displayName != null) 'display_name': displayName,
          if (licenseNumber != null) 'license_number': licenseNumber,
        },
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Driver profile update failed');
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Driver profile update failed',
        code: '${e.response?.statusCode}',
      );
    }
  }
}