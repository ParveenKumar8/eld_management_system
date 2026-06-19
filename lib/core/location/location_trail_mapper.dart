import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:eld_management_system/core/location/location_trail_point.dart';

abstract final class LocationTrailMapper {
  static Map<String, dynamic> toApiJson(LocationTrailPoint point) => {
        'id': point.id,
        'driver_id': point.driverId,
        'recorded_at': point.fix.timestamp.toUtc().toIso8601String(),
        'latitude': point.fix.latitude,
        'longitude': point.fix.longitude,
        'accuracy_meters': point.fix.accuracyMeters,
        'speed_mps': point.fix.speedMps,
        'heading': point.fix.heading,
      };

  static LocationTrailPoint fromApiJson(Map<String, dynamic> json) => LocationTrailPoint(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        fix: LocationFix(
          latitude: (json['latitude'] as num).toDouble(),
          longitude: (json['longitude'] as num).toDouble(),
          timestamp: DateTime.parse(json['recorded_at'] as String),
          accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
          speedMps: (json['speed_mps'] as num?)?.toDouble(),
          heading: (json['heading'] as num?)?.toDouble(),
        ),
      );
}