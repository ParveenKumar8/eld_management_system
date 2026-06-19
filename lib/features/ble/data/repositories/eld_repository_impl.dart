import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_service.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/ble/data/datasources/ble_datasource.dart';
import 'package:eld_management_system/features/ble/data/datasources/eld_local_datasource.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_sync_service.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';

class EldRepositoryImpl implements EldRepository {
  EldRepositoryImpl(
    this._ble,
    this._permissions, {
    EldLocalDataSource? local,
    EldSyncService? sync,
  })  : _local = local,
        _sync = sync;

  final BleDataSource _ble;
  final PermissionService _permissions;
  final EldLocalDataSource? _local;
  final EldSyncService? _sync;

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
  ResultFuture<void> stopScan() async {
    try {
      await _ble.stopScan();
      return const Right(null);
    } catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> connect(String deviceId) async {
    try {
      await _permissions.ensureRequiredGranted();
      await _ble.connect(deviceId);
      return const Right(null);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message, code: e.code));
    } on IncompatibleEldException catch (e) {
      return Left(BleFailure(e.message, code: e.code));
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
  ResultFuture<List<EldData>> getBufferedData() async {
    final local = _local;
    if (local != null) {
      final persisted = await local.listRecent();
      if (persisted.isNotEmpty) {
        return Right(persisted.map((record) => record.data).toList());
      }
    }
    return Right(_ble.buffer);
  }

  @override
  ResultFuture<void> flushBuffer() async {
    await _sync?.flushOutbox();
    _ble.clearBuffer();
    return const Right(null);
  }

  @override
  Future<void> syncPending() async {
    await _sync?.flushOutbox();
  }
}