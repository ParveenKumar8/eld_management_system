import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/features/hos/data/mappers/hos_record_mapper.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';

class HosRemoteDataSource {
  HosRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<HosRecord>> fetchRecords({int days = 8}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/hos/records',
        queryParameters: {'days': days},
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'HOS fetch failed');
      }
      final records = data['records'] as List<dynamic>? ?? [];
      return records
          .map((item) => HosRecordMapper.fromApiJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'HOS fetch failed', code: '${e.response?.statusCode}');
    }
  }

  Future<({List<String> accepted, List<({String id, String reason})> rejected})> syncRecords(
    List<HosRecord> records,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '/hos/records/sync',
        data: {
          'records': records.map(HosRecordMapper.toApiJson).toList(),
        },
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'HOS sync failed');
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
      throw NetworkException(e.message ?? 'HOS sync failed', code: '${e.response?.statusCode}');
    }
  }

  Future<HosRecord> editRecord({
    required String recordId,
    required String annotation,
    DutyStatus? status,
    DateTime? endTime,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/hos/records/$recordId',
        data: {
          'annotation': annotation,
          if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
          if (status != null) 'status': status.code,
        },
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'HOS edit failed');
      }
      return HosRecordMapper.fromApiJson(data);
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'HOS edit failed', code: '${e.response?.statusCode}');
    }
  }

  Future<List<HosRecord>> certifyLogs({int days = 8}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/hos/certify',
        data: {'days': days},
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'HOS certify failed');
      }
      final records = data['records'] as List<dynamic>? ?? [];
      return records
          .map((item) => HosRecordMapper.fromApiJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'HOS certify failed', code: '${e.response?.statusCode}');
    }
  }
}