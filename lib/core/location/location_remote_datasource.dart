import 'package:dio/dio.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/network/api/api_response.dart';
import 'package:eld_management_system/core/location/location_trail_mapper.dart';
import 'package:eld_management_system/core/location/location_trail_point.dart';

class LocationRemoteDataSource {
  LocationRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({List<String> accepted, List<({String id, String reason})> rejected})> uploadBatch(
    List<LocationTrailPoint> points,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '/location/trail/batch',
        data: {
          'points': points.map(LocationTrailMapper.toApiJson).toList(),
        },
      );
      final envelope = parseApiMap(response.data);
      final data = envelope.data;
      if (data == null) {
        throw ServerException(envelope.error?.message ?? 'Location upload failed');
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
      throw NetworkException(
        e.message ?? 'Location upload failed',
        code: '${e.response?.statusCode}',
      );
    }
  }
}