import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';

/// Copy for the ELD devices screen.
abstract final class DeviceStrings {
  static const pageTitle = 'ELD Devices';
  static const connectionStatusTitle = 'Connection Status';
  static const connectionScanning = 'Scanning';
  static const connectionVerifying = 'Verifying ELD';

  static const emptyTitle = 'Ready to scan';
  static const emptySubtitle =
      'Tap Start Scan to discover nearby Bluetooth devices, then select one to verify ELD compatibility.';
  static const startScan = 'Start Scan';

  static const scanningTitle = 'Searching for Bluetooth devices';
  static const scanningSubtitle =
      'Discovering all nearby BLE peripherals. Select a device after the scan to check ELD support.';
  static const scanningCancel = 'Cancel scan';
  static String scanningProgress(int percent) => 'Scan progress · $percent%';
  static String scanningDevicesFound(int count) =>
      count == 1 ? '1 device found so far' : '$count devices found so far';
  static const scanningStillLooking = 'Still searching nearby Bluetooth devices…';

  static const noResultsTitle = 'No Bluetooth devices found';
  static const noResultsSubtitle =
      'The scan finished without detecting any nearby Bluetooth hardware.';
  static const noResultsTipPower = 'Confirm nearby devices are powered on';
  static const noResultsTipRange = 'Move closer to the Bluetooth device';
  static const noResultsTipBluetooth = 'Ensure Bluetooth is enabled on this phone';
  static const scanAgain = 'Scan again';

  static const resultsHeader = 'Nearby Bluetooth devices';
  static String resultsCount(int count) =>
      count == 1 ? '1 device found' : '$count devices found';
  static const resultsHint = 'Tap a device to verify ELD compatibility and connect.';

  static const disconnect = 'Disconnect';
  static const signalExcellent = 'Excellent';
  static const signalGood = 'Good';
  static const signalWeak = 'Weak';
  static const signalLabel = 'Signal';

  static String compatibilityLabel(EldDeviceCompatibility compatibility) =>
      switch (compatibility) {
        EldDeviceCompatibility.unknown => 'Unknown device',
        EldDeviceCompatibility.likely => 'Possible ELD',
        EldDeviceCompatibility.compatible => 'ELD compatible',
        EldDeviceCompatibility.incompatible => 'Not ELD compatible',
      };

  static String signalStrength(int rssi) {
    if (rssi > -60) return signalExcellent;
    if (rssi > -75) return signalGood;
    return signalWeak;
  }

  static String signalDetail(int rssi) =>
      '$signalLabel: ${signalStrength(rssi)} · $rssi dBm';
}