import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ok } from '../common/api-response';
import { DriversService } from './drivers.service';
import { UpdateDriverDto } from './dto/update-driver.dto';

@ApiTags('drivers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class DriversController {
  constructor(private readonly drivers: DriversService) {}

  @Get('drivers/me')
  async getMe(@CurrentUser() user: { id: string }) {
    return ok(await this.drivers.getMe(user.id));
  }

  @Patch('drivers/me')
  async updateMe(
    @CurrentUser() user: { id: string },
    @Body() dto: UpdateDriverDto,
  ) {
    return ok(await this.drivers.updateMe(user.id, dto));
  }

  @Get('carriers/me')
  async getCarrier(@CurrentUser() user: { id: string }) {
    return ok(await this.drivers.getCarrier(user.id));
  }
}