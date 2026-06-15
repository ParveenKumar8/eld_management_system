import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_service.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/ble/data/datasources/ble_datasource.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';

class EldRepositoryImpl implements EldRepository {
  EldRepositoryImpl(this._ble, this._permissions);

  final BleDataSource _ble;
  final PermissionService _permissions;

  @override
  ResultFuture<List<PermissionStatusInfo>> getPermissionStatuses() async {
    try {
      return Right(await _permissions.checkStatuses());
    } catch (e) {
      return Left(PermissionFailure(e.toString()));
    }
  }

  @override
  ResultFuture<PermissionGrantResult> requestPermissions({EldPermissionKind? kind}) async {
    try {
      final result = kind == null
          ? await _permissions.requestAll()
          : await _permissions.requestOne(kind);
      return Right(result);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message, code: e.code));
    } catch (e) {
      return Left(PermissionFailure(e.toString()));
    }
  }

  @override
  ResultFuture<bool> openPermissionSettings() async {
    try {
      return Right(await _permissions.openSettings());
    } catch (e) {
      return Left(PermissionFailure(e.toString()));
    }
  }

  @override
  ResultFuture<bool> isBluetoothAvailable() async {
    try {
      return Right(await _ble.isBluetoothAvailable());
    } catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Stream<List<EldDevice>> scanDevices({Duration timeout = const Duration(seconds: 15)}) async* {
    await _permissions.ensureRequiredGranted();
    yield* _ble.scan(timeout: timeout);
  }

  @override
  ResultFuture<void> connect(String deviceId) async {
    try {
      await _permissions.ensureRequiredGranted();
      await _ble.connect(deviceId);
      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message, code: e.code));
    } on BleException catch (e) {
      return Left(BleFailure(e.message, code: e.code));
    } catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> disconnect() async {
    try {
      await _ble.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Stream<EldData> watchEldData() => _ble.eldDataStream;

  @override
  Stream<EldConnectionState> watchConnectionState() => _ble.connectionState;

  @override
  ResultFuture<List<EldData>> getBufferedData() async => Right(_ble.buffer);

  @override
  ResultFuture<void> flushBuffer() async {
    _ble.clearBuffer();
    return const Right(null);
  }
}