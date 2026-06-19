import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:eld_management_system/core/location/location_trail_mapper.dart';
import 'package:eld_management_system/core/location/location_trail_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips location trail point through API JSON', () {
    final point = LocationTrailPoint(
      id: 'point-1',
      driverId: 'driver-1',
      fix: LocationFix(
        latitude: 33.4484,
        longitude: -112.074,
        timestamp: DateTime.utc(2026, 6, 15, 8, 30),
        accuracyMeters: 12.5,
        speedMps: 24.6,
        heading: 180,
      ),
    );

    final json = LocationTrailMapper.toApiJson(point);
    final restored = LocationTrailMapper.fromApiJson(json);

    expect(restored, point);
    expect(json['driver_id'], 'driver-1');
  });
}