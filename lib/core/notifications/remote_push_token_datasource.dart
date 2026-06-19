import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';

/// Registers the device FCM token with the fleet backend.
class RemotePushTokenDataSource {
  RemotePushTokenDataSource(this._dio);

  final Dio _dio;

  Future<void> registerToken({
    required String driverId,
    required String token,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/notifications/device-token',
        data: {
          'driver_id': driverId,
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      final envelope = parseApiMap(response.data);
      if (envelope.error != null) {
        AppLogger.warning('FCM token registration rejected: ${envelope.error!.message}');
        return;
      }
      AppLogger.info('FCM token registered for driver $driverId');
    } on DioException catch (e) {
      AppLogger.warning('FCM token registration failed', e);
    }
  }

  Future<void> unregisterToken({required String token}) async {
    try {
      await _dio.delete<void>(
        '/notifications/device-token',
        data: {'token': token},
      );
      AppLogger.info('FCM token unregistered');
    } on DioException catch (e) {
      AppLogger.warning('FCM token unregister failed', e);
    }
  }
}