import 'package:eld_management_system/features/hos/data/mappers/hos_record_mapper.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips HOS record through API JSON', () {
    final record = HosRecord(
      id: 'rec-1',
      driverId: 'driver-1',
      status: DutyStatus.driving,
      startTime: DateTime.utc(2026, 6, 3, 8, 0),
      endTime: DateTime.utc(2026, 6, 3, 12, 0),
      annotation: 'Pickup',
      locationLat: 40.1,
      locationLng: -74.2,
      isEdited: true,
      certifiedAt: DateTime.utc(2026, 6, 3, 20, 0),
      vehicleId: 'truck-9',
    );

    final json = HosRecordMapper.toApiJson(record);
    final restored = HosRecordMapper.fromApiJson(json);

    expect(restored, record);
    expect(json['status'], 'D');
    expect(json['driver_id'], 'driver-1');
  });
}