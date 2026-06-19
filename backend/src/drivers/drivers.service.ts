import { Injectable, NotFoundException } from '@nestjs/common';
import { toUserDto } from '../common/user.mapper';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateDriverDto } from './dto/update-driver.dto';

@Injectable()
export class DriversService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Driver not found');
    return toUserDto(user);
  }

  async updateMe(userId: string, dto: UpdateDriverDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName: dto.display_name,
        licenseNumber: dto.license_number,
      },
    });
    return toUserDto(user);
  }

  async getCarrier(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { carrier: true },
    });
    if (!user?.carrier) {
      return null;
    }
    return {
      id: user.carrier.id,
      name: user.carrier.name,
      dot_number: user.carrier.dotNumber,
    };
  }
}