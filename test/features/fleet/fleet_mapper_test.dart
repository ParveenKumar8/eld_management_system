import 'package:eld_management_system/features/fleet/data/mappers/fleet_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses fleet overview and driver snapshot', () {
    final overview = FleetMapper.overviewFromJson({
      'driver_count': 3,
      'violation_count': 1,
      'uncertified_driver_count': 2,
      'edited_driver_count': 1,
      'registered_push_tokens': 4,
    });

    expect(overview.driverCount, 3);
    expect(overview.violationCount, 1);

    final driver = FleetMapper.driverFromJson({
      'id': 'driver-1',
      'email': 'driver@demo.eld',
      'display_name': 'Demo Driver',
      'role': 'driver',
      'current_status': 'D',
      'is_in_violation': false,
      'remaining_drive_minutes': 420,
      'uncertified_count': 2,
      'edited_count': 1,
      'has_push_token': true,
    });

    expect(driver.displayName, 'Demo Driver');
    expect(driver.currentStatus?.code, 'D');
    expect(driver.hasPushToken, isTrue);
  });
}