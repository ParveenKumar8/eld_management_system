import { IsDateString, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';
import { DutyStatus } from '@prisma/client';

export class EditHosRecordDto {
  @IsString()
  @MinLength(1)
  annotation!: string;

  @IsOptional()
  @IsDateString()
  end_time?: string | null;

  @IsOptional()
  @IsEnum(DutyStatus)
  status?: DutyStatus;
}