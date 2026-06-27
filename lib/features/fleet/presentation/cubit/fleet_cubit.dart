import 'package:bloc/bloc.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_driver_snapshot.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_overview.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_push_result.dart';
import 'package:eld_management_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';
import 'package:equatable/equatable.dart';

part 'fleet_state.dart';

class FleetCubit extends Cubit<FleetState> {
  FleetCubit(this._repository) : super(const FleetState());

  final FleetRepository _repository;

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: FleetStatus.loading, clearError: true));
    final overviewResult = await _repository.getOverview();
    final driversResult = await _repository.listDrivers();

    overviewResult.fold(
      (f) => emit(state.copyWith(status: FleetStatus.error, errorMessage: f.message)),
      (overview) {
        driversResult.fold(
          (f) => emit(state.copyWith(status: FleetStatus.error, errorMessage: f.message)),
          (drivers) => emit(
            state.copyWith(
              status: FleetStatus.loaded,
              overview: overview,
              drivers: drivers,
            ),
          ),
        );
      },
    );
  }

  Future<void> selectDriver(String driverId) async {
    emit(
      state.copyWith(
        status: FleetStatus.loading,
        selectedDriverId: driverId,
        clearError: true,
      ),
    );

    final summaryResult = await _repository.getDriverSummary(driverId);
    final recordsResult = await _repository.getDriverRecords(driverId);

    summaryResult.fold(
      (f) => emit(state.copyWith(status: FleetStatus.error, errorMessage: f.message)),
      (summary) {
        recordsResult.fold(
          (f) => emit(state.copyWith(status: FleetStatus.error, errorMessage: f.message)),
          (records) => emit(
            state.copyWith(
              status: FleetStatus.loaded,
              selectedSummary: summary,
              selectedRecords: records,
            ),
          ),
        );
      },
    );
  }

  Future<FleetPushResult?> sendPush({
    required String type,
    required String title,
    required String body,
    String? detail,
    List<String>? driverIds,
  }) async {
    emit(state.copyWith(status: FleetStatus.sending, clearError: true));
    final result = await _repository.sendPush(
      type: type,
      title: title,
      body: body,
      detail: detail,
      driverIds: driverIds,
    );

    return result.fold(
      (f) {
        emit(state.copyWith(status: FleetStatus.error, errorMessage: f.message));
        return null;
      },
      (pushResult) {
        emit(
          state.copyWith(
            status: FleetStatus.loaded,
            lastPushResult: pushResult,
          ),
        );
        return pushResult;
      },
    );
  }
}