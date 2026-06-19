import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/features/ble/data/mappers/eld_telemetry_mapper.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';

class EldRemoteDataSource {
  EldRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({List<String> accepted, List<({String id, String reason})> rejected})> uploadBatch(
    List<EldTelemetryRecord> events,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '/eld/telemetry/batch',
        data: {
          'events': events.map(EldTelemetryMapper.toApiJson).toList(),
        },
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'ELD upload failed');
      }
      final accepted = (data['accepted'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toList();
      final rejected = (data['rejected'] as List<dynamic>? ?? [])
          .map(
            (item) => (
              id: (item as Map<String, dynamic>)['id'] as String,
              reason: item['reason'] as String? ?? 'rejected',
            ),
          )
          .toList();
      return (accepted: accepted, rejected: rejected);
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'ELD upload failed', code: '${e.response?.statusCode}');
    }
  }
}