import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';

/// Dart port of GeometrisMobile Android BLE parsing logic.
/// Parses proprietary Whereqube notification payloads into [EldData].
class GeometrisParser {
  /// Expected minimum payload length for valid frames.
  static const int minFrameLength = 16;

  EldData? parse(List<int> bytes) {
    if (bytes.length < minFrameLength) {
      AppLogger.warning('Geometris frame too short: ${bytes.length}');
      return null;
    }

    try {
      // Frame header validation (0x7E start marker common in Geometris protocol)
      final frameType = bytes[0];
      if (frameType != 0x7E && frameType != 0x02) {
        return _parseAlternateFormat(bytes);
      }
      return _parseStandardFrame(bytes);
    } catch (e, st) {
      AppLogger.error('Geometris parse error', e, st);
      return null;
    }
  }

  EldData _parseStandardFrame(List<int> bytes) {
    // Byte layout adapted from Geometris Whereqube documentation patterns:
    // [0] header, [1-4] timestamp offset, [5-8] odometer, [9-10] speed,
    // [11] movement flags, [12-15] lat/lng scaled integers
    final timestamp = DateTime.now().toUtc();
    final odometerRaw = _readUint32(bytes, 5);
    final speedRaw = _readUint16(bytes, 9);
    final flags = bytes.length > 11 ? bytes[11] : 0;
    final isMoving = (flags & 0x01) != 0;
    final malfunction = (flags & 0x02) != 0;
    final diagnostic = (flags & 0x04) != 0;

    final engineHours = bytes.length > 15
        ? _readUint16(bytes, 13) / 10.0
        : 0.0;

    double? lat;
    double? lng;
    if (bytes.length >= 23) {
      lat = _readInt32(bytes, 15) / 1e6;
      lng = _readInt32(bytes, 19) / 1e6;
    }

    return EldData(
      timestamp: timestamp,
      engineHours: engineHours,
      odometerMiles: odometerRaw / 10.0,
      speedMph: speedRaw / 10.0,
      isMoving: isMoving,
      latitude: lat,
      longitude: lng,
      malfunctionIndicator: malfunction,
      diagnosticIndicator: diagnostic,
      rawPayload: List<int>.from(bytes),
    );
  }

  EldData? _parseAlternateFormat(List<int> bytes) {
    if (bytes.length < 8) return null;
    final speed = bytes[2] / 2.0;
    final moving = bytes[3] > 0;
    return EldData(
      timestamp: DateTime.now().toUtc(),
      engineHours: bytes[4] / 10.0,
      odometerMiles: _readUint16(bytes, 5) / 10.0,
      speedMph: speed,
      isMoving: moving,
      rawPayload: List<int>.from(bytes),
    );
  }

  int _readUint16(List<int> b, int offset) =>
      (b[offset] << 8) | b[offset + 1];

  int _readUint32(List<int> b, int offset) =>
      (b[offset] << 24) | (b[offset + 1] << 16) | (b[offset + 2] << 8) | b[offset + 3];

  int _readInt32(List<int> b, int offset) {
    final v = _readUint32(b, offset);
    return v > 0x7FFFFFFF ? v - 0x100000000 : v;
  }
}