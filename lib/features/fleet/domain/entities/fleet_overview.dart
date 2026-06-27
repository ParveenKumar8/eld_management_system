import 'package:equatable/equatable.dart';

class FleetOverview extends Equatable {
  const FleetOverview({
    required this.driverCount,
    required this.violationCount,
    required this.uncertifiedDriverCount,
    required this.editedDriverCount,
    required this.registeredPushTokens,
  });

  final int driverCount;
  final int violationCount;
  final int uncertifiedDriverCount;
  final int editedDriverCount;
  final int registeredPushTokens;

  @override
  List<Object?> get props => [
        driverCount,
        violationCount,
        uncertifiedDriverCount,
        editedDriverCount,
        registeredPushTokens,
      ];
}