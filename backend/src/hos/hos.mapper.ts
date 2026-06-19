import { DutyStatus, HosRecord } from '@prisma/client';

export interface HosRecordResponse {
  id: string;
  driver_id: string;
  status: DutyStatus;
  start_time: string;
  end_time: string | null;
  annotation: string | null;
  location_lat: number | null;
  location_lng: number | null;
  is_edited: boolean;
  certified_at: string | null;
  vehicle_id: string | null;
}

export function toHosRecordDto(record: HosRecord, driverId: string): HosRecordResponse {
  return {
    id: record.id,
    driver_id: driverId,
    status: record.status,
    start_time: record.startTime.toISOString(),
    end_time: record.endTime?.toISOString() ?? null,
    annotation: record.annotation,
    location_lat: record.locationLat,
    location_lng: record.locationLng,
    is_edited: record.isEdited,
    certified_at: record.certifiedAt?.toISOString() ?? null,
    vehicle_id: record.vehicleId,
  };
}