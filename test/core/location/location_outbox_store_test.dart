import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:eld_management_system/core/location/location_outbox_store.dart';
import 'package:eld_management_system/core/location/location_trail_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late LocationOutboxStore store;

  setUp(() async {
    Hive.init('test_location_outbox');
    await Hive.openBox<String>(AppConstants.hiveBoxLocationOutbox);
    store = LocationOutboxStore();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxLocationOutbox);
  });

  test('enqueues and drains accepted trail points', () async {
    final point = LocationTrailPoint(
      id: 'point-1',
      driverId: 'driver-1',
      fix: LocationFix(
        latitude: 40.0,
        longitude: -75.0,
        timestamp: DateTime.utc(2026, 6, 15, 9),
      ),
    );

    await store.enqueue(point);
    final pending = await store.pending();

    expect(pending, hasLength(1));
    expect(pending.first.point.id, 'point-1');

    await store.removeMany(['point-1']);
    expect(await store.pending(), isEmpty);
  });
}