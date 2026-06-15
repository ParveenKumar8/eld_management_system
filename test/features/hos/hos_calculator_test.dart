import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/services/hos_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HosCalculator calculator;

  setUp(() {
    calculator = HosCalculator();
  });

  test('calculates remaining drive hours with partial day usage', () {
    final now = DateTime.utc(2026, 6, 3, 14, 0);
    final records = [
      HosRecord(
        id: '1',
        driverId: 'd1',
        status: DutyStatus.driving,
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now,
      ),
    ];

    final summary = calculator.calculateSummary(records: records, now: now);

    expect(summary.drivingMinutesToday, 180);
    expect(summary.remainingDriveMinutes, (11 * 60) - 180);
    expect(summary.isInViolation, false);
  });

  test('detects 11-hour driving violation', () {
    final now = DateTime.utc(2026, 6, 3, 20, 0);
    final records = [
      HosRecord(
        id: '1',
        driverId: 'd1',
        status: DutyStatus.driving,
        startTime: now.subtract(const Duration(hours: 12)),
        endTime: now,
      ),
    ];

    final summary = calculator.calculateSummary(records: records, now: now);

    expect(summary.isInViolation, true);
    expect(summary.violationMessage, contains('11-hour'));
  });

  test('suggests driving status when vehicle is moving', () {
    expect(
      calculator.suggestStatusFromEld(isMoving: true, speedMph: 55),
      DutyStatus.driving,
    );
    expect(
      calculator.suggestStatusFromEld(isMoving: false, speedMph: 0),
      DutyStatus.onDutyNotDriving,
    );
  });
}