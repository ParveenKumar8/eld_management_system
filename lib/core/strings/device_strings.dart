/// Copy for the ELD devices screen.
abstract final class DeviceStrings {
  static const pageTitle = 'ELD Devices';
  static const connectionStatusTitle = 'Connection Status';
  static const emptyTitle = 'No devices found';
  static const emptySubtitle =
      'Scan for nearby Geometris Whereqube or compatible ELD hardware.';
  static const startScan = 'Start Scan';
  static const disconnect = 'Disconnect';
  static const signalExcellent = 'Excellent';
  static const signalGood = 'Good';
  static const signalWeak = 'Weak';
  static const signalLabel = 'Signal';

  static String signalStrength(int rssi) {
    if (rssi > -60) return signalExcellent;
    if (rssi > -75) return signalGood;
    return signalWeak;
  }

  static String signalDetail(int rssi) =>
      '$signalLabel: ${signalStrength(rssi)} · $rssi dBm';
}