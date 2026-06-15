import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:eld_management_system/core/location/location_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('test_location_store');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('location_trail')) {
      await Hive.box<String>('location_trail').clear();
    }
  });

  test('persists and restores last fix per driver', () async {
    final store = LocationStore();
    final fix = LocationFix(
      latitude: 33.4484,
      longitude: -112.0740,
      timestamp: DateTime.utc(2026, 6, 15, 8),
    );

    await store.saveFix(driverId: 'driver-1', fix: fix, appendTrail: false);
    final restored = await store.lastFix('driver-1');

    expect(restored, fix);
  });
}