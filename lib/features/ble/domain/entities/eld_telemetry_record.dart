import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:equatable/equatable.dart';

/// Persisted ELD telemetry event with sync metadata.
class EldTelemetryRecord extends Equatable {
  const EldTelemetryRecord({
    required this.id,
    required this.driverId,
    required this.deviceId,
    required this.data,
  });

  final String id;
  final String driverId;
  final String deviceId;
  final EldData data;

  @override
  List<Object?> get props => [id, driverId, deviceId, data];
}