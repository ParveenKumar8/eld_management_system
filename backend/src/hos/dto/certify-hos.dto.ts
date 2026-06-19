import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class CertifyHosDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(30)
  days?: number;
}