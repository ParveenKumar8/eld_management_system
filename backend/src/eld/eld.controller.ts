import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ok } from '../common/api-response';
import { EldTelemetryBatchRequestDto } from './dto/eld-telemetry.dto';
import { EldService } from './eld.service';

@ApiTags('eld')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('eld')
export class EldController {
  constructor(private readonly eld: EldService) {}

  @Get('telemetry')
  async listTelemetry(
    @CurrentUser() user: { id: string },
    @Query('limit') limit?: string,
    @Query('since') since?: string,
  ) {
    const parsedLimit = limit ? Number(limit) : 100;
    const events = await this.eld.listEvents(
      user.id,
      Number.isFinite(parsedLimit) ? parsedLimit : 100,
      since,
    );
    return ok({ events });
  }

  @Post('telemetry/batch')
  async uploadBatch(
    @CurrentUser() user: { id: string },
    @Body() dto: EldTelemetryBatchRequestDto,
  ) {
    return ok(await this.eld.uploadBatch(user.id, dto.events));
  }
}