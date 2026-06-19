import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { LocationTrailPointDto } from './dto/location-trail.dto';
import { toLocationTrailDto } from './location.mapper';

@Injectable()
export class LocationService {
  constructor(private readonly prisma: PrismaService) {}

  async listTrail(userId: string, days = 8, limit = 500) {
    const safeDays = Math.min(Math.max(days, 1), 30);
    const safeLimit = Math.min(Math.max(limit, 1), 1000);
    const cutoff = new Date(Date.now() - safeDays * 24 * 60 * 60 * 1000);

    const points = await this.prisma.locationTrailPoint.findMany({
      where: { userId, recordedAt: { gte: cutoff } },
      orderBy: { recordedAt: 'desc' },
      take: safeLimit,
    });

    return points.map((point) => toLocationTrailDto(point, userId));
  }

  async uploadBatch(userId: string, points: LocationTrailPointDto[]) {
    const accepted: string[] = [];
    const rejected: { id: string; reason: string }[] = [];

    for (const incoming of points) {
      if (incoming.driver_id !== userId) {
        rejected.push({ id: incoming.id, reason: 'driver_id mismatch' });
        continue;
      }

      try {
        await this.upsertPoint(userId, incoming);
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

  private async upsertPoint(userId: string, dto: LocationTrailPointDto) {
    const recordedAt = new Date(dto.recorded_at);
    if (Number.isNaN(recordedAt.getTime())) {
      throw new BadRequestException('invalid recorded_at');
    }

    const data: Prisma.LocationTrailPointUpsertArgs['create'] = {
      id: dto.id,
      userId,
      recordedAt,
      latitude: dto.latitude,
      longitude: dto.longitude,
      accuracyMeters: dto.accuracy_meters ?? null,
      speedMps: dto.speed_mps ?? null,
      heading: dto.heading ?? null,
    };

    await this.prisma.locationTrailPoint.upsert({
      where: { id: dto.id },
      create: data,
      update: {
        recordedAt: data.recordedAt,
        latitude: data.latitude,
        longitude: data.longitude,
        accuracyMeters: data.accuracyMeters,
        speedMps: data.speedMps,
        heading: data.heading,
      },
    });
  }
}