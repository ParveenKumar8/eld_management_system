import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DriversModule } from './drivers/drivers.module';
import { EldModule } from './eld/eld.module';
import { LocationModule } from './location/location.module';
import { FleetModule } from './fleet/fleet.module';
import { HosModule } from './hos/hos.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    DriversModule,
    NotificationsModule,
    HosModule,
    FleetModule,
    EldModule,
    LocationModule,
  ],
})
export class AppModule {}