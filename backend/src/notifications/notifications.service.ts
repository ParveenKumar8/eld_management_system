import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceTokenDto } from './dto/device-token.dto';
import { SendFleetPushDto } from './dto/send-push.dto';
import { FcmService } from './fcm.service';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
  ) {}

  async registerToken(userId: string, dto: RegisterDeviceTokenDto) {
    await this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      create: {
        token: dto.token,
        platform: dto.platform,
        userId,
      },
      update: {
        platform: dto.platform,
        userId,
      },
    });
    return { registered: true };
  }

  async unregisterToken(token: string) {
    await this.prisma.deviceToken.deleteMany({ where: { token } });
    return { unregistered: true };
  }

  async sendFleetPush(
    sender: { id: string; role: UserRole },
    dto: SendFleetPushDto,
  ) {
    if (sender.role !== UserRole.fleet_manager && sender.role !== UserRole.admin) {
      throw new ForbiddenException('Fleet push requires fleet_manager or admin role');
    }

    const senderUser = await this.prisma.user.findUnique({ where: { id: sender.id } });
    if (!senderUser) {
      throw new NotFoundException('Sender not found');
    }

    let driverIds = dto.driver_ids ?? [];
    if (!driverIds.length) {
      if (sender.role === UserRole.admin) {
        const drivers = await this.prisma.user.findMany({
          where: { role: UserRole.driver },
          select: { id: true },
        });
        driverIds = drivers.map((d) => d.id);
      } else if (senderUser.carrierId) {
        const drivers = await this.prisma.user.findMany({
          where: { role: UserRole.driver, carrierId: senderUser.carrierId },
          select: { id: true },
        });
        driverIds = drivers.map((d) => d.id);
      }
    } else if (sender.role === UserRole.fleet_manager && senderUser.carrierId) {
      const allowed = await this.prisma.user.findMany({
        where: {
          id: { in: driverIds },
          role: UserRole.driver,
          carrierId: senderUser.carrierId,
        },
        select: { id: true },
      });
      driverIds = allowed.map((d) => d.id);
    }

    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId: { in: driverIds } },
      select: { token: true },
    });

    const delivery = await this.fcm.sendToTokens(
      tokens.map((t) => t.token),
      {
        type: dto.type,
        title: dto.title,
        body: dto.body,
        detail: dto.detail,
        route: dto.route,
      },
    );

    return {
      targeted_drivers: driverIds.length,
      device_tokens: tokens.length,
      ...delivery,
    };
  }
}