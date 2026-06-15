import 'package:equatable/equatable.dart';

enum EldConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error,
}

class EldDevice extends Equatable {
  const EldDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.serialNumber,
  });

  final String id;
  final String name;
  final int rssi;
  final String? serialNumber;

  @override
  List<Object?> get props => [id, name, rssi, serialNumber];
}