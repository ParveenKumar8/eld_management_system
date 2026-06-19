import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { EldTelemetryEventDto } from './dto/eld-telemetry.dto';
import { toEldTelemetryDto } from './eld.mapper';

@Injectable()
export class EldService {
  constructor(private readonly prisma: PrismaService) {}

  async listEvents(userId: string, limit = 100, since?: string) {
    const safeLimit = Math.min(Math.max(limit, 1), 500);
    const sinceDate = since ? new Date(since) : undefined;
    if (since && Number.isNaN(sinceDate!.getTime())) {
      throw new BadRequestException('invalid since timestamp');
    }

    const events = await this.prisma.eldTelemetryEvent.findMany({
      where: {
        userId,
        ...(sinceDate ? { recordedAt: { gte: sinceDate } } : {}),
      },
      orderBy: { recordedAt: 'desc' },
      take: safeLimit,
    });

    return events.map((event) => toEldTelemetryDto(event, userId));
  }

  async uploadBatch(userId: string, events: EldTelemetryEventDto[]) {
    const accepted: string[] = [];
    const rejected: { id: string; reason: string }[] = [];

    for (const incoming of events) {
      if (incoming.driver_id !== userId) {
        rejected.push({ id: incoming.id, reason: 'driver_id mismatch' });
        continue;
      }

      try {
        await this.upsertEvent(userId, incoming);
        accepted.push(incoming.id);
      } catch (error) {
        rejected.push({
          id: incoming.id,
          reason: error instanceof Error ? error.message : 'upsert failed',
        });
      }
    }

    return { accepted, rejected };
  }

  private async upsertEvent(userId: string, dto: EldTelemetryEventDto) {
    const recordedAt = new Date(dto.recorded_at);
    if (Number.isNaN(recordedAt.getTime())) {
      throw new BadRequestException('invalid recorded_at');
    }

    const data: Prisma.EldTelemetryEventUpsertArgs['create'] = {
      id: dto.id,
      userId,
      deviceId: dto.device_id,
      recordedAt,
      engineHours: dto.engine_hours,
      odometerMiles: dto.odometer_miles,
      speedMph: dto.speed_mph,
      isMoving: dto.is_moving,
      latitude: dto.latitude ?? null,
      longitude: dto.longitude ?? null,
      vin: dto.vin ?? null,
      malfunctionIndicator: dto.malfunction_indicator ?? false,
      diagnosticIndicator: dto.diagnostic_indicator ?? false,
      rawPayloadHex: dto.raw_payload_hex ?? null,
    };

    await this.prisma.eldTelemetryEvent.upsert({
      where: { id: dto.id },
      create: data,
      update: {
        deviceId: data.deviceId,
        recordedAt: data.recordedAt,
        engineHours: data.engineHours,
        odometerMiles: data.odometerMiles,
        speedMph: data.speedMph,
        isMoving: data.isMoving,
        latitude: data.latitude,
        longitude: data.longitude,
        vin: data.vin,
        malfunctionIndicator: data.malfunctionIndicator,
        diagnosticIndicator: data.diagnosticIndicator,
        rawPayloadHex: data.rawPayloadHex,
      },
    });
  }
}