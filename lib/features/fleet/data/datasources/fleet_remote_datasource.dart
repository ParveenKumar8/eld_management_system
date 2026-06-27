import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/features/fleet/data/mappers/fleet_mapper.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_driver_snapshot.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_overview.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_push_result.dart';
import 'package:eld_management_system/features/hos/data/mappers/hos_record_mapper.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

class FleetRemoteDataSource {
  FleetRemoteDataSource(this._dio);
  final Dio _dio;

  Future<FleetOverview> fetchOverview() async {
    try {
      final response = await _dio.get<dynamic>('/fleet/overview');
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Fleet overview failed');
      }
      return FleetMapper.overviewFromJson(data);
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Fleet overview failed',
        code: '${e.response?.statusCode}',
      );
    }
  }

  Future<List<FleetDriverSnapshot>> fetchDrivers() async {
    try {
      final response = await _dio.get<dynamic>('/fleet/drivers');
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Fleet drivers failed');
      }
      final drivers = data['drivers'] as List<dynamic>? ?? [];
      return drivers
          .map((item) => FleetMapper.driverFromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Fleet drivers failed',
        code: '${e.response?.statusCode}',
      );
    }
  }

  Future<HosSummary> fetchDriverSummary(String driverId) async {
    try {
      final response = await _dio.get<dynamic>('/fleet/drivers/$driverId/hos/summary');
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Driver summary failed');
      }
      return FleetMapper.summaryFromJson(data);
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Driver summary failed',
        code: '${e.response?.statusCode}',
      );
    }
  }

  Future<List<HosRecord>> fetchDriverRecords(String driverId, {int days = 8}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/fleet/drivers/$driverId/hos/records',
        queryParameters: {'days': days},
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Driver records failed');
      }
      final records = data['records'] as List<dynamic>? ?? [];
      return records
          .map((item) => HosRecordMapper.fromApiJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Driver records failed',
        code: '${e.response?.statusCode}',
      );
    }
  }

  Future<FleetPushResult> sendPush({
    required String type,
    required String title,
    required String body,
    String? detail,
    String? route,
    List<String>? driverIds,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/notifications/push',
        data: {
          'type': type,
          'title': title,
          'body': body,
          if (detail != null) 'detail': detail,
          if (route != null) 'route': route,
          if (driverIds != null && driverIds.isNotEmpty) 'driver_ids': driverIds,
        },
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Fleet push failed');
      }
      return FleetMapper.pushResultFromJson(data);
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Fleet push failed',
        code: '${e.response?.statusCode}',
      );
    }
  }
}