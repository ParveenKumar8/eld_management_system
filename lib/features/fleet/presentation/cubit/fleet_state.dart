part of 'fleet_cubit.dart';

enum FleetStatus { initial, loading, loaded, error, sending }

class FleetState extends Equatable {
  const FleetState({
    this.status = FleetStatus.initial,
    this.overview,
    this.drivers = const [],
    this.selectedDriverId,
    this.selectedSummary,
    this.selectedRecords = const [],
    this.lastPushResult,
    this.errorMessage,
  });

  final FleetStatus status;
  final FleetOverview? overview;
  final List<FleetDriverSnapshot> drivers;
  final String? selectedDriverId;
  final HosSummary? selectedSummary;
  final List<HosRecord> selectedRecords;
  final FleetPushResult? lastPushResult;
  final String? errorMessage;

  FleetDriverSnapshot? get selectedDriver {
    if (selectedDriverId == null) return null;
    for (final driver in drivers) {
      if (driver.id == selectedDriverId) return driver;
    }
    return null;
  }

  FleetState copyWith({
    FleetStatus? status,
    FleetOverview? overview,
    List<FleetDriverSnapshot>? drivers,
    String? selectedDriverId,
    HosSummary? selectedSummary,
    List<HosRecord>? selectedRecords,
    FleetPushResult? lastPushResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FleetState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      drivers: drivers ?? this.drivers,
      selectedDriverId: selectedDriverId ?? this.selectedDriverId,
      selectedSummary: selectedSummary ?? this.selectedSummary,
      selectedRecords: selectedRecords ?? this.selectedRecords,
      lastPushResult: lastPushResult ?? this.lastPushResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        overview,
        drivers,
        selectedDriverId,
        selectedSummary,
        selectedRecords,
        lastPushResult,
        errorMessage,
      ];
}