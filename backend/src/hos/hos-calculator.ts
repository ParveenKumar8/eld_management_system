import { DutyStatus, HosRecord } from '@prisma/client';

const MAX_DRIVING_MINUTES_PER_DAY = 11 * 60;
const MAX_ON_DUTY_MINUTES_PER_DAY = 14 * 60;
const MAX_DRIVING_MINUTES_PER_WEEK = 60 * 60;

export interface HosSummaryDto {
  remaining_drive_minutes: number;
  remaining_on_duty_minutes: number;
  remaining_cycle_minutes: number;
  driving_minutes_today: number;
  on_duty_minutes_today: number;
  off_duty_minutes_since_last_reset: number;
  is_in_violation: boolean;
  violation_message: string | null;
}

function recordMinutes(record: HosRecord, now: Date): number {
  const end = record.endTime ?? now;
  return Math.max(0, Math.floor((end.getTime() - record.startTime.getTime()) / 60_000));
}

export function calculateHosSummary(records: HosRecord[], now = new Date()): HosSummaryDto {
  const dayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const todayRecords = records.filter((r) => r.startTime >= dayStart);

  let drivingMinutes = 0;
  let onDutyMinutes = 0;
  let offDutyMinutes = 0;

  for (const record of todayRecords) {
    const minutes = recordMinutes(record, now);
    switch (record.status) {
      case DutyStatus.D:
        drivingMinutes += minutes;
        onDutyMinutes += minutes;
        break;
      case DutyStatus.ON:
        onDutyMinutes += minutes;
        break;
      case DutyStatus.OFF:
      case DutyStatus.SB:
        offDutyMinutes += minutes;
        break;
    }
  }

  const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const weekDriving = records
    .filter((r) => r.status === DutyStatus.D && r.startTime >= weekStart)
    .reduce((sum, r) => sum + recordMinutes(r, now), 0);

  const remainingDrive = Math.max(0, MAX_DRIVING_MINUTES_PER_DAY - drivingMinutes);
  const remainingOnDuty = Math.max(0, MAX_ON_DUTY_MINUTES_PER_DAY - onDutyMinutes);
  const remainingCycle = Math.max(0, MAX_DRIVING_MINUTES_PER_WEEK - weekDriving);

  let violationMessage: string | null = null;
  let isInViolation = false;
  if (drivingMinutes > MAX_DRIVING_MINUTES_PER_DAY) {
    isInViolation = true;
    violationMessage = 'Exceeded 11-hour driving limit';
  } else if (onDutyMinutes > MAX_ON_DUTY_MINUTES_PER_DAY) {
    isInViolation = true;
    violationMessage = 'Exceeded 14-hour on-duty window';
  } else if (weekDriving > MAX_DRIVING_MINUTES_PER_WEEK) {
    isInViolation = true;
    violationMessage = 'Exceeded 60-hour/7-day cycle';
  }

  return {
    remaining_drive_minutes: remainingDrive,
    remaining_on_duty_minutes: remainingOnDuty,
    remaining_cycle_minutes: remainingCycle,
    driving_minutes_today: drivingMinutes,
    on_duty_minutes_today: onDutyMinutes,
    off_duty_minutes_since_last_reset: offDutyMinutes,
    is_in_violation: isInViolation,
    violation_message: violationMessage,
  };
}