import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_local_datasource.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';
import 'package:eld_management_system/features/hos/domain/repositories/hos_repository.dart';
import 'package:eld_management_system/features/hos/domain/services/hos_calculator.dart';

class HosRepositoryImpl implements HosRepository {
  HosRepositoryImpl({
    required HosLocalDataSource local,
    required HosCalculator calculator,
  })  : _local = local,
        _calculator = calculator;

  final HosLocalDataSource _local;
  final HosCalculator _calculator;

  @override
  ResultFuture<List<HosRecord>> getRecords({String? driverId, int days = 8}) async {
    try {
      return Right(await _local.getRecords(driverId: driverId, days: days));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<HosRecord> changeDutyStatus({
    required String driverId,
    required DutyStatus status,
    String? annotation,
    double? lat,
    double? lng,
  }) async {
    try {
      if (status == DutyStatus.offDuty && (annotation == null || annotation.isEmpty)) {
        // FMCSA may require annotation for certain edits; allow status change
      }
      final record = await _local.createDutyChange(
        driverId: driverId,
        status: status,
        annotation: annotation,
        lat: lat,
        lng: lng,
      );
      return Right(record);
    } catch (e) {
      return Left(HosFailure(e.toString()));
    }
  }

  @override
  ResultFuture<HosSummary> getSummary(String driverId) async {
    try {
      final records = await _local.getRecords(driverId: driverId, days: 8);
      return Right(
        _calculator.calculateSummary(records: records, now: DateTime.now().toUtc()),
      );
    } catch (e) {
      return Left(HosFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> logMalfunction({
    required String driverId,
    required String code,
  }) async {
    try {
      await _local.createDutyChange(
        driverId: driverId,
        status: DutyStatus.onDutyNotDriving,
        annotation: 'MALFUNCTION: $code',
      );
      return const Right(null);
    } catch (e) {
      return Left(HosFailure(e.toString()));
    }
  }

  @override
  ResultFuture<String> exportForInspection({
    required String driverId,
    required int days,
  }) async {
    try {
      final json = await _local.exportJson(driverId: driverId, days: days);
      return Right(json);
    } catch (e) {
      return Left(HosFailure(e.toString()));
    }
  }

  @override
  Stream<List<HosRecord>> watchRecords(String driverId) async* {
    while (true) {
      yield await _local.getRecords(driverId: driverId, days: 8);
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }
}