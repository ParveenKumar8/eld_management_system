import { IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateDriverDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  display_name?: string;

  @IsOptional()
  @IsString()
  license_number?: string;
}