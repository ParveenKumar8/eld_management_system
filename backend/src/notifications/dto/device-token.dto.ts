import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsOptional()
  @IsString()
  driver_id?: string;

  @IsString()
  @MinLength(1)
  token!: string;

  @IsIn(['ios', 'android'])
  platform!: 'ios' | 'android';
}

export class UnregisterDeviceTokenDto {
  @IsString()
  @MinLength(1)
  token!: string;
}