import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/failures.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_status_info.dart';
import 'package:eld_management_system/core/strings/permission_strings.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEldRepository extends Mock implements EldRepository {}

void main() {
  late MockEldRepository repository;

  const grantedStatuses = [
    PermissionStatusInfo(
      kind: EldPermissionKind.bluetooth,
      status: AppPermissionDisplayStatus.granted,
      required: true,
    ),
    PermissionStatusInfo(
      kind: EldPermissionKind.locationWhenInUse,
      status: AppPermissionDisplayStatus.granted,
      required: true,
    ),
  ];

  const deniedStatuses = [
    PermissionStatusInfo(
      kind: EldPermissionKind.bluetooth,
      status: AppPermissionDisplayStatus.denied,
      required: true,
    ),
  ];

  EldBloc buildBloc() {
    repository = MockEldRepository();
    when(() => repository.isBluetoothAvailable()).thenAnswer((_) async => const Right(true));
    when(() => repository.watchConnectionState()).thenAnswer((_) => const Stream.empty());
    when(() => repository.stopScan()).thenAnswer((_) async => const Right(null));
    return EldBloc(repository);
  }

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 15));
  });

  blocTest<EldBloc, EldState>(
    'persists permissionsGranted on EldInitial after permission success',
    build: () {
      final bloc = buildBloc();
      when(() => repository.getPermissionStatuses())
          .thenAnswer((_) async => const Right(grantedStatuses));
      when(() => repository.requestPermissions()).thenAnswer(
        (_) async => const Right(
          PermissionGrantResult(
            allRequiredGranted: true,
            statuses: grantedStatuses,
          ),
        ),
      );
      return bloc;
    },
    act: (b) => b.add(const EldPermissionsRequested()),
    verify: (b) {
      expect(b.state.permissionsGranted, isTrue);
      expect(b.state.permissionStatuses, grantedStatuses);
    },
  );

  blocTest<EldBloc, EldState>(
    'starts scanning UI after permissions are granted',
    build: () {
      final controller = StreamController<List<EldDevice>>();
      final bloc = buildBloc();
      when(() => repository.scanDevices(timeout: any(named: 'timeout')))
          .thenAnswer((_) => controller.stream);
      addTearDown(controller.close);
      return bloc;
    },
    seed: () => const EldInitial(
      permissionsGranted: true,
      permissionStatuses: grantedStatuses,
    ),
    act: (b) => b.add(const EldScanStarted()),
    verify: (b) {
      expect(b.state, isA<EldScanning>());
      expect(b.state.scanPhase, EldScanPhase.scanning);
      expect(b.state.scanStartedAt, isNotNull);
      expect(b.state.connectionState, EldConnectionState.scanning);
    },
  );

  blocTest<EldBloc, EldState>(
    'reverts scan UI when permissions are denied',
    build: () {
      final bloc = buildBloc();
      when(() => repository.getPermissionStatuses())
          .thenAnswer((_) async => const Right(deniedStatuses));
      when(() => repository.requestPermissions()).thenAnswer(
        (_) async => Left(PermissionFailure(PermissionStrings.deniedSummaryPrefix)),
      );
      return bloc;
    },
    act: (b) => b.add(const EldScanStarted()),
    verify: (b) {
      expect(b.state.scanPhase, EldScanPhase.idle);
      expect(b.state.scanStartedAt, isNull);
      expect(b.state.permissionsGranted, isFalse);
      expect(b.state.permissionStatuses, deniedStatuses);
    },
  );
}