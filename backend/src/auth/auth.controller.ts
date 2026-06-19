import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ok } from '../common/api-response';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';
import { SocialAuthDto } from './dto/social-auth.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return ok(await this.auth.register(dto));
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    return ok(await this.auth.login(dto));
  }

  @Post('social')
  async social(@Body() dto: SocialAuthDto) {
    return ok(await this.auth.socialAuth(dto));
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshDto) {
    return ok(await this.auth.refresh(dto.refresh_token));
  }

  @Post('logout')
  async logout(@Body() dto: RefreshDto) {
    return ok(await this.auth.logout(dto.refresh_token));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async me(@CurrentUser() user: { id: string }) {
    return ok(await this.auth.getMe(user.id));
  }
}