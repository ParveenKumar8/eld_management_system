import { Module } from '@nestjs/common';
import { RolesGuard } from '../auth/roles.guard';
import { FcmService } from './fcm.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, FcmService, RolesGuard],
})
export class NotificationsModule {}