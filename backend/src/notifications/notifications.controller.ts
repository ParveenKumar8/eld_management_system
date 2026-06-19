import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { ok } from '../common/api-response';
import { RegisterDeviceTokenDto, UnregisterDeviceTokenDto } from './dto/device-token.dto';
import { SendFleetPushDto } from './dto/send-push.dto';
import { NotificationsService } from './notifications.service';

@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post('device-token')
  async register(
    @CurrentUser() user: { id: string },
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return ok(await this.notifications.registerToken(user.id, dto));
  }

  @Delete('device-token')
  async unregister(@Body() dto: UnregisterDeviceTokenDto) {
    return ok(await this.notifications.unregisterToken(dto.token));
  }

  @Post('push')
  @UseGuards(RolesGuard)
  @Roles(UserRole.fleet_manager, UserRole.admin)
  async sendFleetPush(
    @CurrentUser() user: { id: string; role: UserRole },
    @Body() dto: SendFleetPushDto,
  ) {
    return ok(await this.notifications.sendFleetPush(user, dto));
  }
}