import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const carrier = await prisma.carrier.upsert({
    where: { dotNumber: 'DOT-DEMO-001' },
    update: {},
    create: {
      name: 'Demo Fleet Carrier',
      dotNumber: 'DOT-DEMO-001',
    },
  });

  const passwordHash = await bcrypt.hash('password123', 12);
  await prisma.user.upsert({
    where: { email: 'driver@demo.eld' },
    update: {},
    create: {
      email: 'driver@demo.eld',
      passwordHash,
      displayName: 'Demo Driver',
      role: UserRole.driver,
      licenseNumber: 'CDL-DEMO-1234',
      carrierId: carrier.id,
    },
  });

  const fleetPasswordHash = await bcrypt.hash('fleet123', 12);
  await prisma.user.upsert({
    where: { email: 'fleet@demo.eld' },
    update: {},
    create: {
      email: 'fleet@demo.eld',
      passwordHash: fleetPasswordHash,
      displayName: 'Demo Fleet Manager',
      role: UserRole.fleet_manager,
      carrierId: carrier.id,
    },
  });

  console.log('Seed complete:');
  console.log('  driver@demo.eld / password123');
  console.log('  fleet@demo.eld / fleet123');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });