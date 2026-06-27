import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_driver_snapshot.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_overview.dart';
import 'package:eld_management_system/features/fleet/domain/entities/fleet_push_result.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

abstract class FleetRepository {
  ResultFuture<FleetOverview> getOverview();
  ResultFuture<List<FleetDriverSnapshot>> listDrivers();
  ResultFuture<HosSummary> getDriverSummary(String driverId);
  ResultFuture<List<HosRecord>> getDriverRecords(String driverId, {int days = 8});
  ResultFuture<FleetPushResult> sendPush({
    required String type,
    required String title,
    required String body,
    String? detail,
    String? route,
    List<String>? driverIds,
  });
}