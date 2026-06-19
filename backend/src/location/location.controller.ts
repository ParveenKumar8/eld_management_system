import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ok } from '../common/api-response';
import { LocationTrailBatchRequestDto } from './dto/location-trail.dto';
import { LocationService } from './location.service';

@ApiTags('location')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('location')
export class LocationController {
  constructor(private readonly location: LocationService) {}

  @Get('trail')
  async listTrail(
    @CurrentUser() user: { id: string },
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    const parsedDays = days ? Number(days) : 8;
    const parsedLimit = limit ? Number(limit) : 500;
    const points = await this.location.listTrail(
      user.id,
      Number.isFinite(parsedDays) ? parsedDays : 8,
      Number.isFinite(parsedLimit) ? parsedLimit : 500,
    );
    return ok({ points });
  }

  @Post('trail/batch')
  async uploadBatch(
    @CurrentUser() user: { id: string },
    @Body() dto: LocationTrailBatchRequestDto,
  ) {
    return ok(await this.location.uploadBatch(user.id, dto.points));
  }
}