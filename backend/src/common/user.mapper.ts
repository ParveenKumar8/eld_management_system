import { User } from '@prisma/client';

export function toUserDto(user: User) {
  return {
    id: user.id,
    email: user.email,
    display_name: user.displayName,
    role: user.role,
    license_number: user.licenseNumber,
    carrier_id: user.carrierId,
  };
}