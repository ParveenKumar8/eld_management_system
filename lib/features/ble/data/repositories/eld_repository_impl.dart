import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/exceptions.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/ble/data/datasources/ble_datasource.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_data.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';

class EldRepositoryImpl implements EldRepository {
  EldRepositoryImpl(this._ble);
  final BleDataSource _ble;

  @override
  ResultFuture<bool> requestPermissions() async {
    try {
      final ok = await _ble.requestPermissions();
      return Right(ok);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message, code: e.code));
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
  Stream<List<EldDevice>> scanDevices({Duration timeout = const Duration(seconds: 15)}) {
    return _ble.scan(timeout: timeout);
  }

  @override
  ResultFuture<void> connect(String deviceId) async {
    try {
      await _ble.connect(deviceId);
      return const Right(null);
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