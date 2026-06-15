import 'package:bloc/bloc.dart';
import 'package:eld_management_system/core/location/location_tracking_service.dart';
import 'package:eld_management_system/core/notifications/driver_notification_dispatcher.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';
import 'package:eld_management_system/features/hos/domain/repositories/hos_repository.dart';
import 'package:equatable/equatable.dart';

part 'hos_state.dart';

class HosCubit extends Cubit<HosState> {
  HosCubit(
    this._repository,
    this._notifications,
    this._location,
  ) : super(const HosState());

  final HosRepository _repository;
  final DriverNotificationDispatcher _notifications;
  final LocationTrackingService _location;

  Future<void> load(String driverId) async {
    emit(state.copyWith(status: HosStatus.loading));
    final recordsResult = await _repository.getRecords(driverId: driverId);
    final summaryResult = await _repository.getSummary(driverId);

    recordsResult.fold(
      (f) => emit(state.copyWith(status: HosStatus.error, errorMessage: f.message)),
      (records) {
        summaryResult.fold(
          (f) => emit(state.copyWith(status: HosStatus.error, errorMessage: f.message)),
          (summary) {
            emit(
              state.copyWith(
                status: HosStatus.loaded,
                records: records,
                summary: summary,
              ),
            );
            _notifications.onHosSummary(summary);
          },
        );
      },
    );
  }

  Future<void> changeStatus({
    required String driverId,
    required DutyStatus status,
    String? annotation,
  }) async {
    emit(state.copyWith(status: HosStatus.loading));
    final fix = _location.lastFix;
    final result = await _repository.changeDutyStatus(
      driverId: driverId,
      status: status,
      annotation: annotation,
      lat: fix?.latitude,
      lng: fix?.longitude,
    );
    result.fold(
      (f) => emit(state.copyWith(status: HosStatus.error, errorMessage: f.message)),
      (_) => load(driverId),
    );
  }

  Future<String?> exportLogs(String driverId) async {
    final result = await _repository.exportForInspection(driverId: driverId, days: 8);
    return result.fold((_) => null, (json) => json);
  }
}