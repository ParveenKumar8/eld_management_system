import 'package:eld_management_system/features/ble/domain/entities/eld_device_compatibility.dart';
import 'package:equatable/equatable.dart';

enum EldConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  verifying,
  error,
}

class EldDevice extends Equatable {
  const EldDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.serialNumber,
    this.compatibility = EldDeviceCompatibility.unknown,
  });

  final String id;
  final String name;
  final int rssi;
  final String? serialNumber;
  final EldDeviceCompatibility compatibility;

  EldDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    String? serialNumber,
    EldDeviceCompatibility? compatibility,
  }) =>
      EldDevice(
        id: id ?? this.id,
        name: name ?? this.name,
        rssi: rssi ?? this.rssi,
        serialNumber: serialNumber ?? this.serialNumber,
        compatibility: compatibility ?? this.compatibility,
      );

  @override
  List<Object?> get props => [id, name, rssi, serialNumber, compatibility];
}