import 'package:eld_management_system/features/ble/data/mappers/eld_telemetry_mapper.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips ELD telemetry through API JSON', () {
    final record = EldTelemetryRecord(
      id: 'evt-1',
      driverId: 'driver-1',
      deviceId: 'ble-device-1',
      data: EldData(
        timestamp: DateTime.utc(2026, 6, 3, 14, 30),
        engineHours: 120.5,
        odometerMiles: 45123.2,
        speedMph: 62.5,
        isMoving: true,
        latitude: 40.7128,
        longitude: -74.006,
        vin: '1HGBH41JXMN109186',
        malfunctionIndicator: false,
        diagnosticIndicator: true,
        rawPayload: [0x7E, 0x02, 0x10, 0xFF],
      ),
    );

    final json = EldTelemetryMapper.toApiJson(record);
    final restored = EldTelemetryMapper.fromApiJson(json);

    expect(restored.id, record.id);
    expect(restored.driverId, record.driverId);
    expect(restored.deviceId, record.deviceId);
    expect(restored.data.engineHours, record.data.engineHours);
    expect(restored.data.rawPayload, record.data.rawPayload);
    expect(json['raw_payload_hex'], '7e0210ff');
  });

  test('round-trips through local JSON', () {
    final record = EldTelemetryRecord(
      id: 'evt-2',
      driverId: 'driver-2',
      deviceId: 'ble-device-2',
      data: EldData(
        timestamp: DateTime.utc(2026, 6, 3, 15, 0),
        engineHours: 1,
        odometerMiles: 2,
        speedMph: 0,
        isMoving: false,
      ),
    );

    final restored = EldTelemetryMapper.fromLocalJson(
      EldTelemetryMapper.toLocalJson(record),
    );

    expect(restored, record);
  });
}