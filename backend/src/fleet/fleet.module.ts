import { Module } from '@nestjs/common';
import { RolesGuard } from '../auth/roles.guard';
import { HosModule } from '../hos/hos.module';
import { FleetController } from './fleet.controller';
import { FleetService } from './fleet.service';

@Module({
  imports: [HosModule],
  controllers: [FleetController],
  providers: [FleetService, RolesGuard],
})
export class FleetModule {}