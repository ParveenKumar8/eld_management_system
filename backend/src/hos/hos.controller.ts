import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ok } from '../common/api-response';
import { CertifyHosDto } from './dto/certify-hos.dto';
import { EditHosRecordDto } from './dto/edit-hos-record.dto';
import { HosSyncRequestDto } from './dto/hos-record.dto';
import { HosService } from './hos.service';

@ApiTags('hos')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('hos')
export class HosController {
  constructor(private readonly hos: HosService) {}

  @Get('records')
  async listRecords(
    @CurrentUser() user: { id: string },
    @Query('days') days?: string,
  ) {
    const parsedDays = days ? Number(days) : 8;
    const safeDays = Number.isFinite(parsedDays)
      ? Math.min(Math.max(parsedDays, 1), 30)
      : 8;
    const records = await this.hos.listRecords(user.id, safeDays);
    return ok({ records });
  }

  @Post('records/sync')
  async syncRecords(
    @CurrentUser() user: { id: string },
    @Body() dto: HosSyncRequestDto,
  ) {
    return ok(await this.hos.syncRecords(user.id, dto.records));
  }

  @Get('summary')
  async summary(@CurrentUser() user: { id: string }) {
    return ok(await this.hos.getSummary(user.id));
  }

  @Patch('records/:id')
  async editRecord(
    @CurrentUser() user: { id: string },
    @Param('id') recordId: string,
    @Body() dto: EditHosRecordDto,
  ) {
    return ok(await this.hos.editRecord(user.id, recordId, dto));
  }

  @Post('certify')
  async certify(
    @CurrentUser() user: { id: string },
    @Body() dto: CertifyHosDto,
  ) {
    return ok(await this.hos.certifyLogs(user.id, dto));
  }
}