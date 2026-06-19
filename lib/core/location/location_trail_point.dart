import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:equatable/equatable.dart';

/// A GPS trail point queued for server sync.
class LocationTrailPoint extends Equatable {
  const LocationTrailPoint({
    required this.id,
    required this.driverId,
    required this.fix,
  });

  final String id;
  final String driverId;
  final LocationFix fix;

  @override
  List<Object?> get props => [id, driverId, fix];
}