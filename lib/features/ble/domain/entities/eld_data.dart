import 'package:equatable/equatable.dart';

/// Parsed ELD telemetry from connected device (Geometris-compatible).
class EldData extends Equatable {
  const EldData({
    required this.timestamp,
    required this.engineHours,
    required this.odometerMiles,
    required this.speedMph,
    required this.isMoving,
    this.latitude,
    this.longitude,
    this.vin,
    this.malfunctionIndicator = false,
    this.diagnosticIndicator = false,
    this.rawPayload,
  });

  final DateTime timestamp;
  final double engineHours;
  final double odometerMiles;
  final double speedMph;
  final bool isMoving;
  final double? latitude;
  final double? longitude;
  final String? vin;
  final bool malfunctionIndicator;
  final bool diagnosticIndicator;
  final List<int>? rawPayload;

  @override
  List<Object?> get props => [
        timestamp,
        engineHours,
        odometerMiles,
        speedMph,
        isMoving,
        latitude,
        longitude,
        vin,
        malfunctionIndicator,
        diagnosticIndicator,
      ];
}