import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

abstract interface class HosRepository {
  ResultFuture<List<HosRecord>> getRecords({String? driverId, int days = 8});
  ResultFuture<HosRecord> changeDutyStatus({
    required String driverId,
    required DutyStatus status,
    String? annotation,
    double? lat,
    double? lng,
  });
  ResultFuture<HosSummary> getSummary(String driverId);
  ResultFuture<void> logMalfunction({required String driverId, required String code});
  ResultFuture<String> exportForInspection({required String driverId, required int days});
  Stream<List<HosRecord>> watchRecords(String driverId);
  Future<void> syncPending();
  ResultFuture<HosRecord> editRecord({
    required String driverId,
    required String recordId,
    required String annotation,
    DutyStatus? status,
    DateTime? endTime,
  });
  ResultFuture<int> certifyLogs({required String driverId, int days = 8});
}