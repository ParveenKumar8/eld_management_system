import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { calculateHosSummary } from './hos-calculator';
import { CertifyHosDto } from './dto/certify-hos.dto';
import { EditHosRecordDto } from './dto/edit-hos-record.dto';
import { HosRecordDto } from './dto/hos-record.dto';
import { toHosRecordDto } from './hos.mapper';

@Injectable()
export class HosService {
  constructor(private readonly prisma: PrismaService) {}

  async listRecords(userId: string, days = 8) {
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const records = await this.prisma.hosRecord.findMany({
      where: { userId, startTime: { gte: cutoff } },
      orderBy: { startTime: 'desc' },
    });
    return records.map((record) => toHosRecordDto(record, userId));
  }

  async syncRecords(userId: string, records: HosRecordDto[]) {
    const accepted: string[] = [];
    const rejected: { id: string; reason: string }[] = [];

    for (const incoming of records) {
      if (incoming.driver_id !== userId) {
        rejected.push({ id: incoming.id, reason: 'driver_id mismatch' });
        continue;
      }

      try {
        await this.upsertRecord(userId, incoming);
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

  async editRecord(userId: string, recordId: string, dto: EditHosRecordDto) {
    const existing = await this.prisma.hosRecord.findUnique({ where: { id: recordId } });
    if (!existing || existing.userId !== userId) {
      throw new NotFoundException('HOS record not found');
    }

    const updated = await this.prisma.hosRecord.update({
      where: { id: recordId },
      data: {
        annotation: dto.annotation,
        endTime: dto.end_time ? new Date(dto.end_time) : existing.endTime,
        status: dto.status ?? existing.status,
        isEdited: true,
      },
    });

    return toHosRecordDto(updated, userId);
  }

  async certifyLogs(userId: string, dto: CertifyHosDto) {
    const days = dto.days ?? 8;
    const safeDays = Math.min(Math.max(days, 1), 30);
    const cutoff = new Date(Date.now() - safeDays * 24 * 60 * 60 * 1000);
    const now = new Date();

    const result = await this.prisma.hosRecord.updateMany({
      where: {
        userId,
        startTime: { gte: cutoff },
        certifiedAt: null,
      },
      data: { certifiedAt: now },
    });

    const records = await this.prisma.hosRecord.findMany({
      where: { userId, startTime: { gte: cutoff } },
      orderBy: { startTime: 'desc' },
    });

    return {
      certified_count: result.count,
      certified_at: now.toISOString(),
      records: records.map((record) => toHosRecordDto(record, userId)),
    };
  }

  async getSummary(userId: string) {
    const records = await this.prisma.hosRecord.findMany({
      where: {
        userId,
        startTime: { gte: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000) },
      },
    });
    return calculateHosSummary(records);
  }

  private async upsertRecord(userId: string, dto: HosRecordDto) {
    const startTime = new Date(dto.start_time);
    if (Number.isNaN(startTime.getTime())) {
      throw new BadRequestException('invalid start_time');
    }

    const data: Prisma.HosRecordUpsertArgs['create'] = {
      id: dto.id,
      userId,
      status: dto.status,
      startTime,
      endTime: dto.end_time ? new Date(dto.end_time) : null,
      annotation: dto.annotation ?? null,
      locationLat: dto.location_lat ?? null,
      locationLng: dto.location_lng ?? null,
      isEdited: dto.is_edited ?? false,
      certifiedAt: dto.certified_at ? new Date(dto.certified_at) : null,
      vehicleId: dto.vehicle_id ?? null,
    };

    await this.prisma.hosRecord.upsert({
      where: { id: dto.id },
      create: data,
      update: {
        status: data.status,
        startTime: data.startTime,
        endTime: data.endTime,
        annotation: data.annotation,
        locationLat: data.locationLat,
        locationLng: data.locationLng,
        isEdited: data.isEdited,
        certifiedAt: data.certifiedAt,
        vehicleId: data.vehicleId,
      },
    });
  }
}