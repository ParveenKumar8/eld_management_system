import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';

abstract final class HosRecordMapper {
  static Map<String, dynamic> toApiJson(HosRecord record) => {
        'id': record.id,
        'driver_id': record.driverId,
        'status': record.status.code,
        'start_time': record.startTime.toIso8601String(),
        'end_time': record.endTime?.toIso8601String(),
        'annotation': record.annotation,
        'location_lat': record.locationLat,
        'location_lng': record.locationLng,
        'is_edited': record.isEdited,
        'certified_at': record.certifiedAt?.toIso8601String(),
        'vehicle_id': record.vehicleId,
      };

  static HosRecord fromApiJson(Map<String, dynamic> json) => HosRecord(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        status: DutyStatus.fromCode(json['status'] as String),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String)
            : null,
        annotation: json['annotation'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        isEdited: json['is_edited'] as bool? ?? false,
        certifiedAt: json['certified_at'] != null
            ? DateTime.parse(json['certified_at'] as String)
            : null,
        vehicleId: json['vehicle_id'] as String?,
      );
}