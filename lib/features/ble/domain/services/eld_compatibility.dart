import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Heuristics for identifying Geometris / FMCSA ELD hardware.
abstract final class EldCompatibility {
  static const _nameHints = ['WHERE', 'WHEREQUBE', 'GEOMETRIS', 'ELD'];

  static EldDeviceCompatibility hintFromAdvertisement({
    required String name,
    required List<Guid> serviceUuids,
  }) {
    if (isLikelyEldName(name) || advertisesEldService(serviceUuids)) {
      return EldDeviceCompatibility.likely;
    }
    return EldDeviceCompatibility.unknown;
  }

  static bool isLikelyEldName(String name) {
    final upper = name.toUpperCase();
    return _nameHints.any(upper.contains);
  }

  static bool advertisesEldService(List<Guid> serviceUuids) {
    for (final uuid in serviceUuids) {
      if (_isEldServiceUuid(uuid.str)) return true;
    }
    return false;
  }

  static bool hasEldServices(List<BluetoothService> services) {
    for (final service in services) {
      if (_isEldServiceUuid(service.uuid.str)) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            return true;
          }
        }
      }
    }
    return _findFirstNotifiable(services) != null;
  }

  static BluetoothCharacteristic? findEldNotifyCharacteristic(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      if (!_isEldServiceUuid(service.uuid.str)) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          return characteristic;
        }
      }
    }
    return _findFirstNotifiable(services);
  }

  static BluetoothCharacteristic? _findFirstNotifiable(List<BluetoothService> services) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.notify) return characteristic;
      }
    }
    return null;
  }

  static bool _isEldServiceUuid(String uuid) {
    final normalized = uuid.toLowerCase();
    return normalized.contains('fff0') ||
        normalized == AppConstants.geometrisServiceUuid.toLowerCase();
  }
}