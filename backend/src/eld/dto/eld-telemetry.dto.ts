import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  ValidateNested,
} from 'class-validator';

export class EldTelemetryEventDto {
  @IsUUID()
  id!: string;

  @IsString()
  driver_id!: string;

  @IsString()
  device_id!: string;

  @IsDateString()
  recorded_at!: string;

  @IsNumber()
  engine_hours!: number;

  @IsNumber()
  odometer_miles!: number;

  @IsNumber()
  speed_mph!: number;

  @IsBoolean()
  is_moving!: boolean;

  @IsOptional()
  @IsNumber()
  latitude?: number | null;

  @IsOptional()
  @IsNumber()
  longitude?: number | null;

  @IsOptional()
  @IsString()
  vin?: string | null;

  @IsOptional()
  @IsBoolean()
  malfunction_indicator?: boolean;

  @IsOptional()
  @IsBoolean()
  diagnostic_indicator?: boolean;

  @IsOptional()
  @IsString()
  raw_payload_hex?: string | null;
}

export class EldTelemetryBatchRequestDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EldTelemetryEventDto)
  events!: EldTelemetryEventDto[];
}