import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes and deserializes location fix', () {
    final fix = LocationFix(
      latitude: 40.7128,
      longitude: -74.0060,
      timestamp: DateTime.utc(2026, 6, 15, 12),
      accuracyMeters: 8.5,
      speedMps: 12.3,
      heading: 90,
    );

    final restored = LocationFix.fromJson(fix.toJson());
    expect(restored, fix);
  });

  test('converts speed to mph', () {
    final fix = LocationFix(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.utc(2026, 1, 1),
      speedMps: 10,
    );

    expect(fix.speedMph, closeTo(22.3694, 0.01));
  });
}