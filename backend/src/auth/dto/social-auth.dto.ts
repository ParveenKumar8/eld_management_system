import { IsIn, IsString, MinLength } from 'class-validator';

export class SocialAuthDto {
  @IsIn(['google', 'facebook', 'apple'])
  provider!: 'google' | 'facebook' | 'apple';

  @IsString()
  @MinLength(1)
  id_token!: string;
}