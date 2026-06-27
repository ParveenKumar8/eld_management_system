import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { User, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { calculateHosSummary } from '../hos/hos-calculator';
import { HosService } from '../hos/hos.service';
import { toUserDto } from '../common/user.mapper';

type FleetRequester = { id: string; role: UserRole };

@Injectable()
export class FleetService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly hos: HosService,
  ) {}

  async getOverview(requester: FleetRequester) {
    const drivers = await this.listDriverUsers(requester);
    const driverIds = drivers.map((d) => d.id);
    const days = 8;
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    let violations = 0;
    let uncertifiedDrivers = 0;
    let editedDrivers = 0;

    for (const driver of drivers) {
      const records = await this.prisma.hosRecord.findMany({
        where: { userId: driver.id, startTime: { gte: cutoff } },
      });
      const summary = calculateHosSummary(records);
      if (summary.is_in_violation) violations += 1;

      const uncertified = records.some((r) => r.certifiedAt == null);
      if (uncertified) uncertifiedDrivers += 1;

      if (records.some((r) => r.isEdited)) editedDrivers += 1;
    }

    const pushTokens = await this.prisma.deviceToken.count({
      where: { userId: { in: driverIds } },
    });

    return {
      driver_count: drivers.length,
      violation_count: violations,
      uncertified_driver_count: uncertifiedDrivers,
      edited_driver_count: editedDrivers,
      registered_push_tokens: pushTokens,
    };
  }

  async listDrivers(requester: FleetRequester) {
    const drivers = await this.listDriverUsers(requester);
    const days = 8;
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const driverIds = drivers.map((d) => d.id);

    const tokenCounts = await this.prisma.deviceToken.groupBy({
      by: ['userId'],
      where: { userId: { in: driverIds } },
      _count: { _all: true },
    });
    const tokenMap = new Map(tokenCounts.map((t) => [t.userId, t._count._all]));

    const snapshots = [];
    for (const driver of drivers) {
      const records = await this.prisma.hosRecord.findMany({
        where: { userId: driver.id, startTime: { gte: cutoff } },
        orderBy: { startTime: 'desc' },
      });
      const summary = calculateHosSummary(records);
      const active = records.find((r) => r.endTime == null) ?? records[0];

      snapshots.push({
        ...toUserDto(driver),
        current_status: active?.status ?? null,
        is_in_violation: summary.is_in_violation,
        violation_message: summary.violation_message,
        remaining_drive_minutes: summary.remaining_drive_minutes,
        uncertified_count: records.filter((r) => r.certifiedAt == null).length,
        edited_count: records.filter((r) => r.isEdited).length,
        has_push_token: (tokenMap.get(driver.id) ?? 0) > 0,
      });
    }

    return { drivers: snapshots };
  }

  async getDriverRecords(requester: FleetRequester, driverId: string, days = 8) {
    await this.assertDriverAccess(requester, driverId);
    const safeDays = Math.min(Math.max(days, 1), 30);
    const records = await this.hos.listRecords(driverId, safeDays);
    return { records };
  }

  async getDriverSummary(requester: FleetRequester, driverId: string) {
    await this.assertDriverAccess(requester, driverId);
    return this.hos.getSummary(driverId);
  }

  private async listDriverUsers(requester: FleetRequester): Promise<User[]> {
    if (requester.role === UserRole.admin) {
      return this.prisma.user.findMany({
        where: { role: UserRole.driver },
        orderBy: { displayName: 'asc' },
      });
    }

    if (requester.role !== UserRole.fleet_manager) {
      throw new ForbiddenException('Fleet access requires fleet_manager or admin role');
    }

    const manager = await this.prisma.user.findUnique({ where: { id: requester.id } });
    if (!manager?.carrierId) {
      throw new ForbiddenException('Fleet manager is not assigned to a carrier');
    }

    return this.prisma.user.findMany({
      where: { role: UserRole.driver, carrierId: manager.carrierId },
      orderBy: { displayName: 'asc' },
    });
  }

  private async assertDriverAccess(requester: FleetRequester, driverId: string): Promise<User> {
    const driver = await this.prisma.user.findUnique({ where: { id: driverId } });
    if (!driver || driver.role !== UserRole.driver) {
      throw new NotFoundException('Driver not found');
    }

    if (requester.role === UserRole.admin) {
      return driver;
    }

    if (requester.role !== UserRole.fleet_manager) {
      throw new ForbiddenException('Fleet access requires fleet_manager or admin role');
    }

    const manager = await this.prisma.user.findUnique({ where: { id: requester.id } });
    if (!manager?.carrierId || driver.carrierId !== manager.carrierId) {
      throw new ForbiddenException('Driver is outside your carrier');
    }

    return driver;
  }
}