import { LocationTrailPoint } from '@prisma/client';

export interface LocationTrailPointResponse {
  id: string;
  driver_id: string;
  recorded_at: string;
  latitude: number;
  longitude: number;
  accuracy_meters: number | null;
  speed_mps: number | null;
  heading: number | null;
}

export function toLocationTrailDto(
  point: LocationTrailPoint,
  driverId: string,
): LocationTrailPointResponse {
  return {
    id: point.id,
    driver_id: driverId,
    recorded_at: point.recordedAt.toISOString(),
    latitude: point.latitude,
    longitude: point.longitude,
    accuracy_meters: point.accuracyMeters,
    speed_mps: point.speedMps,
    heading: point.heading,
  };
}