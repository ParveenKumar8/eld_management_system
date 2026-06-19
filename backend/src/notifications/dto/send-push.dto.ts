import { IsArray, IsOptional, IsString, MinLength } from 'class-validator';

export class SendFleetPushDto {
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  driver_ids?: string[];

  @IsString()
  @MinLength(1)
  type!: string;

  @IsString()
  @MinLength(1)
  title!: string;

  @IsString()
  @MinLength(1)
  body!: string;

  @IsOptional()
  @IsString()
  detail?: string;

  @IsOptional()
  @IsString()
  route?: string;
}