import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_local_datasource.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_remote_datasource.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_outbox_store.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_sync_service.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';
import 'package:eld_management_system/features/hos/domain/repositories/hos_repository.dart';
import 'package:eld_management_system/features/hos/domain/services/hos_calculator.dart';

class HosRepositoryImpl implements HosRepository {
  HosRepositoryImpl({
    required HosLocalDataSource local,
    required HosCalculator calculator,
    HosOutboxStore? outbox,
    HosSyncService? sync,
    HosRemoteDataSource? remote,
  })  : _local = local,
        _calculator = calculator,
        _outbox = outbox,
        _sync = sync,
        _remote = remote;

  final HosLocalDataSource _local;
  final HosCalculator _calculator;
  final HosOutboxStore? _outbox;
  final HosSyncService? _sync;
  final HosRemoteDataSource? _remote;

  @override
  ResultFuture<List<HosRecord>> getRecords({String? driverId, int days = 8}) async {
    try {
      await _sync?.pullAndMerge(days: days);
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
      final change = await _local.createDutyChange(
        driverId: driverId,
        status: status,
        annotation: annotation,
        lat: lat,
        lng: lng,
      );
      await _enqueueForSync([...change.closed, change.created]);
      return Right(change.created);
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
      final change = await _local.createDutyChange(
        driverId: driverId,
        status: DutyStatus.onDutyNotDriving,
        annotation: 'MALFUNCTION: $code',
      );
      await _enqueueForSync([...change.closed, change.created]);
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

  @override
  Future<void> syncPending() async {
    await _sync?.flushOutbox();
  }

  @override
  ResultFuture<HosRecord> editRecord({
    required String driverId,
    required String recordId,
    required String annotation,
    DutyStatus? status,
    DateTime? endTime,
  }) async {
    try {
      var updated = await _local.editRecord(
        recordId: recordId,
        driverId: driverId,
        annotation: annotation,
        status: status,
        endTime: endTime,
      );

      if (_sync != null && await _sync.canSync()) {
        try {
          updated = await _remote!.editRecord(
            recordId: recordId,
            annotation: annotation,
            status: status,
            endTime: endTime,
          );
          await _local.insertRecord(updated);
        } catch (e, st) {
          AppLogger.warning('HOS remote edit failed, queued locally', e, st);
        }
      }

      await _enqueueForSync([updated]);
      return Right(updated);
    } catch (e) {
      return Left(HosFailure(e.toString()));
    }
  }

  @override
  ResultFuture<int> certifyLogs({required String driverId, int days = 8}) async {
    try {
      if (_sync != null && await _sync.canSync()) {
        try {
          final remoteRecords = await _remote!.certifyLogs(days: days);
          await _local.mergeRecords(remoteRecords);
          return Right(remoteRecords.where((r) => r.certifiedAt != null).length);
        } catch (e, st) {
          AppLogger.warning('HOS remote certify failed, using local', e, st);
        }
      }

      final certified = await _local.certifyLogs(driverId: driverId, days: days);
      await _enqueueForSync(certified);
      return Right(certified.length);
    } catch (e) {
      return Left(HosFailure(e.toString()));
    }
  }

  Future<void> _enqueueForSync(List<HosRecord> records) async {
    final outbox = _outbox;
    final sync = _sync;
    if (outbox == null || sync == null || records.isEmpty) return;

    for (final record in records) {
      await outbox.enqueue(record);
    }

    unawaited(
      sync.flushOutbox().catchError((Object e, StackTrace st) {
        AppLogger.warning('HOS immediate sync failed', e, st);
        return 0;
      }),
    );
  }
}