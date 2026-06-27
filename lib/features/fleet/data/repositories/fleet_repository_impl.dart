import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/fleet/data/datasources/fleet_remote_datasource.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_driver_snapshot.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_overview.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_push_result.dart';
import 'package:eld_management_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

class FleetRepositoryImpl implements FleetRepository {
  FleetRepositoryImpl(this._remote);
  final FleetRemoteDataSource _remote;

  @override
  ResultFuture<FleetOverview> getOverview() => _guard(_remote.fetchOverview);

  @override
  ResultFuture<List<FleetDriverSnapshot>> listDrivers() => _guard(_remote.fetchDrivers);

  @override
  ResultFuture<HosSummary> getDriverSummary(String driverId) =>
      _guard(() => _remote.fetchDriverSummary(driverId));

  @override
  ResultFuture<List<HosRecord>> getDriverRecords(String driverId, {int days = 8}) =>
      _guard(() => _remote.fetchDriverRecords(driverId, days: days));

  @override
  ResultFuture<FleetPushResult> sendPush({
    required String type,
    required String title,
    required String body,
    String? detail,
    String? route,
    List<String>? driverIds,
  }) =>
      _guard(
        () => _remote.sendPush(
          type: type,
          title: title,
          body: body,
          detail: detail,
          route: route,
          driverIds: driverIds,
        ),
      );

  ResultFuture<T> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}