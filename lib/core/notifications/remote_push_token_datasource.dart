import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';

/// Registers the device FCM token with the fleet backend.
class RemotePushTokenDataSource {
  RemotePushTokenDataSource(this._dio);

  final Dio _dio;

  Future<void> registerToken({
    required String driverId,
    required String token,
  }) async {
    try {
      await _dio.post<void>(
        '/notifications/device-token',
        data: {
          'driver_id': driverId,
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
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