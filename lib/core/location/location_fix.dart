import 'package:equatable/equatable.dart';

/// A single GPS reading from the device location service.
class LocationFix extends Equatable {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
    this.speedMps,
    this.heading,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyMeters;
  final double? speedMps;
  final double? heading;

  double? get speedMph => speedMps == null ? null : speedMps! * 2.23694;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'accuracy_meters': accuracyMeters,
        'speed_mps': speedMps,
        'heading': heading,
      };

  factory LocationFix.fromJson(Map<String, dynamic> json) => LocationFix(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
        speedMps: (json['speed_mps'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        timestamp,
        accuracyMeters,
        speedMps,
        heading,
      ];
}