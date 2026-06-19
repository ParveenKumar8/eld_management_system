import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_outbox_store.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late EldOutboxStore store;

  setUp(() async {
    Hive.init('test_eld_outbox');
    await Hive.openBox<String>(AppConstants.hiveBoxEldOutbox);
    store = EldOutboxStore();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxEldOutbox);
  });

  test('enqueues and drains accepted telemetry events', () async {
    final record = EldTelemetryRecord(
      id: 'evt-1',
      driverId: 'driver-1',
      deviceId: 'device-1',
      data: EldData(
        timestamp: DateTime.utc(2026, 6, 3, 8, 0),
        engineHours: 10,
        odometerMiles: 1000,
        speedMph: 55,
        isMoving: true,
      ),
    );

    await store.enqueue(record);
    final pending = await store.pending();

    expect(pending, hasLength(1));
    expect(pending.first.record.id, 'evt-1');

    await store.removeMany(['evt-1']);
    expect(await store.pending(), isEmpty);
  });
}