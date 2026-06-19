import { EldTelemetryEvent } from '@prisma/client';

export interface EldTelemetryEventResponse {
  id: string;
  driver_id: string;
  device_id: string;
  recorded_at: string;
  engine_hours: number;
  odometer_miles: number;
  speed_mph: number;
  is_moving: boolean;
  latitude: number | null;
  longitude: number | null;
  vin: string | null;
  malfunction_indicator: boolean;
  diagnostic_indicator: boolean;
  raw_payload_hex: string | null;
}

export function toEldTelemetryDto(
  event: EldTelemetryEvent,
  driverId: string,
): EldTelemetryEventResponse {
  return {
    id: event.id,
    driver_id: driverId,
    device_id: event.deviceId,
    recorded_at: event.recordedAt.toISOString(),
    engine_hours: event.engineHours,
    odometer_miles: event.odometerMiles,
    speed_mph: event.speedMph,
    is_moving: event.isMoving,
    latitude: event.latitude,
    longitude: event.longitude,
    vin: event.vin,
    malfunction_indicator: event.malfunctionIndicator,
    diagnostic_indicator: event.diagnosticIndicator,
    raw_payload_hex: event.rawPayloadHex,
  };
}