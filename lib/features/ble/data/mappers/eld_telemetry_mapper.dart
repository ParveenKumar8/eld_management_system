import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';

abstract final class EldTelemetryMapper {
  static Map<String, dynamic> toApiJson(EldTelemetryRecord record) => {
        'id': record.id,
        'driver_id': record.driverId,
        'device_id': record.deviceId,
        'recorded_at': record.data.timestamp.toIso8601String(),
        'engine_hours': record.data.engineHours,
        'odometer_miles': record.data.odometerMiles,
        'speed_mph': record.data.speedMph,
        'is_moving': record.data.isMoving,
        'latitude': record.data.latitude,
        'longitude': record.data.longitude,
        'vin': record.data.vin,
        'malfunction_indicator': record.data.malfunctionIndicator,
        'diagnostic_indicator': record.data.diagnosticIndicator,
        'raw_payload_hex': _encodeRawPayload(record.data.rawPayload),
      };

  static EldTelemetryRecord fromApiJson(Map<String, dynamic> json) {
    final rawHex = json['raw_payload_hex'] as String?;
    return EldTelemetryRecord(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      deviceId: json['device_id'] as String,
      data: EldData(
        timestamp: DateTime.parse(json['recorded_at'] as String),
        engineHours: (json['engine_hours'] as num).toDouble(),
        odometerMiles: (json['odometer_miles'] as num).toDouble(),
        speedMph: (json['speed_mph'] as num).toDouble(),
        isMoving: json['is_moving'] as bool,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        vin: json['vin'] as String?,
        malfunctionIndicator: json['malfunction_indicator'] as bool? ?? false,
        diagnosticIndicator: json['diagnostic_indicator'] as bool? ?? false,
        rawPayload: _decodeRawPayload(rawHex),
      ),
    );
  }

  static Map<String, dynamic> toLocalJson(EldTelemetryRecord record) => {
        'id': record.id,
        'driver_id': record.driverId,
        'device_id': record.deviceId,
        ..._dataToLocalMap(record.data),
      };

  static EldTelemetryRecord fromLocalJson(Map<String, dynamic> json) => EldTelemetryRecord(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        deviceId: json['device_id'] as String,
        data: _dataFromLocalMap(json),
      );

  static Map<String, dynamic> _dataToLocalMap(EldData data) => {
        'recorded_at': data.timestamp.toIso8601String(),
        'engine_hours': data.engineHours,
        'odometer_miles': data.odometerMiles,
        'speed_mph': data.speedMph,
        'is_moving': data.isMoving,
        'latitude': data.latitude,
        'longitude': data.longitude,
        'vin': data.vin,
        'malfunction_indicator': data.malfunctionIndicator,
        'diagnostic_indicator': data.diagnosticIndicator,
        'raw_payload_hex': _encodeRawPayload(data.rawPayload),
      };

  static EldData _dataFromLocalMap(Map<String, dynamic> json) => EldData(
        timestamp: DateTime.parse(json['recorded_at'] as String),
        engineHours: (json['engine_hours'] as num).toDouble(),
        odometerMiles: (json['odometer_miles'] as num).toDouble(),
        speedMph: (json['speed_mph'] as num).toDouble(),
        isMoving: json['is_moving'] as bool,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        vin: json['vin'] as String?,
        malfunctionIndicator: json['malfunction_indicator'] as bool? ?? false,
        diagnosticIndicator: json['diagnostic_indicator'] as bool? ?? false,
        rawPayload: _decodeRawPayload(json['raw_payload_hex'] as String?),
      );

  static String? _encodeRawPayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static List<int>? _decodeRawPayload(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.length.isOdd ? '0$hex' : hex;
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}