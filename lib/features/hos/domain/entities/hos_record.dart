import 'package:equatable/equatable.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';

/// Hours of Service log entry per FMCSA ELD output requirements.
class HosRecord extends Equatable {
  const HosRecord({
    required this.id,
    required this.driverId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.annotation,
    this.locationLat,
    this.locationLng,
    this.isEdited = false,
    this.certifiedAt,
    this.vehicleId,
  });

  final String id;
  final String driverId;
  final DutyStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? annotation;
  final double? locationLat;
  final double? locationLng;
  final bool isEdited;
  final DateTime? certifiedAt;
  final String? vehicleId;

  Duration get duration {
    final end = endTime ?? DateTime.now().toUtc();
    return end.difference(startTime);
  }

  HosRecord copyWith({
    DateTime? endTime,
    String? annotation,
    bool? isEdited,
    DateTime? certifiedAt,
  }) {
    return HosRecord(
      id: id,
      driverId: driverId,
      status: status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      annotation: annotation ?? this.annotation,
      locationLat: locationLat,
      locationLng: locationLng,
      isEdited: isEdited ?? this.isEdited,
      certifiedAt: certifiedAt ?? this.certifiedAt,
      vehicleId: vehicleId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        status,
        startTime,
        endTime,
        annotation,
        locationLat,
        locationLng,
        isEdited,
        certifiedAt,
        vehicleId,
      ];
}