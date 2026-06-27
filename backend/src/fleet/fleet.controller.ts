import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { ok } from '../common/api-response';
import { FleetService } from './fleet.service';

@ApiTags('fleet')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.fleet_manager, UserRole.admin)
@Controller('fleet')
export class FleetController {
  constructor(private readonly fleet: FleetService) {}

  @Get('overview')
  async overview(@CurrentUser() user: { id: string; role: UserRole }) {
    return ok(await this.fleet.getOverview(user));
  }

  @Get('drivers')
  async listDrivers(@CurrentUser() user: { id: string; role: UserRole }) {
    return ok(await this.fleet.listDrivers(user));
  }

  @Get('drivers/:driverId/hos/records')
  async driverRecords(
    @CurrentUser() user: { id: string; role: UserRole },
    @Param('driverId') driverId: string,
    @Query('days') days?: string,
  ) {
    const parsedDays = days ? Number(days) : 8;
    const safeDays = Number.isFinite(parsedDays) ? parsedDays : 8;
    return ok(await this.fleet.getDriverRecords(user, driverId, safeDays));
  }

  @Get('drivers/:driverId/hos/summary')
  async driverSummary(
    @CurrentUser() user: { id: string; role: UserRole },
    @Param('driverId') driverId: string,
  ) {
    return ok(await this.fleet.getDriverSummary(user, driverId));
  }
}