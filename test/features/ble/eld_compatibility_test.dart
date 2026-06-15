import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';
import 'package:eld_management_system/features/ble/domain/services/eld_compatibility.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EldCompatibility', () {
    test('detects likely ELD from device name', () {
      expect(
        EldCompatibility.hintFromAdvertisement(
          name: 'Whereqube-1234',
          serviceUuids: const [],
        ),
        EldDeviceCompatibility.likely,
      );
    });

    test('marks unknown generic devices during scan', () {
      expect(
        EldCompatibility.hintFromAdvertisement(
          name: 'Living Room Speaker',
          serviceUuids: const [],
        ),
        EldDeviceCompatibility.unknown,
      );
    });

    test('detects likely ELD from advertised service uuid', () {
      expect(
        EldCompatibility.hintFromAdvertisement(
          name: 'Bluetooth device',
          serviceUuids: [Guid('0000fff0-0000-1000-8000-00805f9b34fb')],
        ),
        EldDeviceCompatibility.likely,
      );
    });
  });
}