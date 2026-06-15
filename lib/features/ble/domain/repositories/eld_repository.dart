import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';

abstract interface class EldRepository {
  ResultFuture<List<PermissionStatusInfo>> getPermissionStatuses();
  ResultFuture<PermissionGrantResult> requestPermissions({EldPermissionKind? kind});
  ResultFuture<bool> openPermissionSettings();
  ResultFuture<bool> isBluetoothAvailable();
  Stream<List<EldDevice>> scanDevices({Duration timeout = const Duration(seconds: 15)});
  ResultFuture<void> connect(String deviceId);
  ResultFuture<void> disconnect();
  Stream<EldData> watchEldData();
  Stream<EldConnectionState> watchConnectionState();
  ResultFuture<List<EldData>> getBufferedData();
  ResultFuture<void> flushBuffer();
}