import { Type } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  ValidateNested,
} from 'class-validator';

export class LocationTrailPointDto {
  @IsUUID()
  id!: string;

  @IsString()
  driver_id!: string;

  @IsDateString()
  recorded_at!: string;

  @IsNumber()
  latitude!: number;

  @IsNumber()
  longitude!: number;

  @IsOptional()
  @IsNumber()
  accuracy_meters?: number | null;

  @IsOptional()
  @IsNumber()
  speed_mps?: number | null;

  @IsOptional()
  @IsNumber()
  heading?: number | null;
}

export class LocationTrailBatchRequestDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LocationTrailPointDto)
  points!: LocationTrailPointDto[];
}