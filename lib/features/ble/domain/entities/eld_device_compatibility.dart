/// How closely a scanned BLE peripheral matches ELD hardware.
enum EldDeviceCompatibility {
  /// Discovered during scan; compatibility not yet checked.
  unknown,

  /// Name or advertised services suggest a Geometris / ELD unit.
  likely,

  /// Service discovery confirmed ELD-capable hardware.
  compatible,

  /// User selected device but it failed ELD verification.
  incompatible,
}