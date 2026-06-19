import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_outbox_store.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late HosOutboxStore store;

  setUp(() async {
    Hive.init('test_hos_outbox');
    await Hive.openBox<String>(AppConstants.hiveBoxHosOutbox);
    store = HosOutboxStore();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxHosOutbox);
  });

  test('enqueues and drains accepted records', () async {
    final record = HosRecord(
      id: 'rec-1',
      driverId: 'driver-1',
      status: DutyStatus.offDuty,
      startTime: DateTime.utc(2026, 6, 3, 8, 0),
    );

    await store.enqueue(record);
    final pending = await store.pending();

    expect(pending, hasLength(1));
    expect(pending.first.record.id, 'rec-1');

    await store.removeMany(['rec-1']);
    expect(await store.pending(), isEmpty);
  });
}