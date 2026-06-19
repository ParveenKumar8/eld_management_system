import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  ValidateNested,
} from 'class-validator';
import { DutyStatus } from '@prisma/client';

export class HosRecordDto {
  @IsUUID()
  id!: string;

  @IsString()
  driver_id!: string;

  @IsEnum(DutyStatus)
  status!: DutyStatus;

  @IsDateString()
  start_time!: string;

  @IsOptional()
  @IsDateString()
  end_time?: string | null;

  @IsOptional()
  @IsString()
  annotation?: string | null;

  @IsOptional()
  @IsNumber()
  location_lat?: number | null;

  @IsOptional()
  @IsNumber()
  location_lng?: number | null;

  @IsOptional()
  @IsBoolean()
  is_edited?: boolean;

  @IsOptional()
  @IsDateString()
  certified_at?: string | null;

  @IsOptional()
  @IsString()
  vehicle_id?: string | null;
}

export class HosSyncRequestDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => HosRecordDto)
  records!: HosRecordDto[];
}