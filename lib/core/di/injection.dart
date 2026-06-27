import 'package:dio/dio.dart';
import 'package:eld_management_system/core/network/dio_client.dart';
import 'package:eld_management_system/core/location/location_outbox_store.dart';
import 'package:eld_management_system/core/location/location_remote_datasource.dart';
import 'package:eld_management_system/core/location/location_store.dart';
import 'package:eld_management_system/core/location/location_sync_service.dart';
import 'package:eld_management_system/core/location/location_trail_buffer.dart';
import 'package:eld_management_system/core/location/location_tracking_service.dart';
import 'package:eld_management_system/core/notifications/driver_notification_dispatcher.dart';
import 'package:eld_management_system/core/notifications/remote_push_service.dart';
import 'package:eld_management_system/core/notifications/remote_push_token_datasource.dart';
import 'package:eld_management_system/core/notifications/notification_preferences_store.dart';
import 'package:eld_management_system/core/notifications/notification_service.dart';
import 'package:eld_management_system/core/notifications/notification_tap_handler.dart';
import 'package:eld_management_system/core/permissions/permission_service.dart';
import 'package:eld_management_system/core/security/secure_storage_service.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:eld_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:eld_management_system/features/auth/data/datasources/driver_remote_datasource.dart';
import 'package:eld_management_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_pending_store.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_sync_service.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:eld_management_system/features/ble/data/datasources/ble_datasource.dart';
import 'package:eld_management_system/features/ble/data/datasources/eld_local_datasource.dart';
import 'package:eld_management_system/features/ble/data/datasources/eld_remote_datasource.dart';
import 'package:eld_management_system/features/ble/data/parsers/geometris_parser.dart';
import 'package:eld_management_system/features/ble/data/repositories/eld_repository_impl.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_outbox_store.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_sync_service.dart';
import 'package:eld_management_system/features/ble/data/sync/eld_telemetry_buffer.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';
import 'package:eld_management_system/features/fleet/data/datasources/fleet_remote_datasource.dart';
import 'package:eld_management_system/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:eld_management_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_local_datasource.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_remote_datasource.dart';
import 'package:eld_management_system/features/hos/data/repositories/hos_repository_impl.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_outbox_store.dart';
import 'package:eld_management_system/features/hos/data/sync/hos_sync_service.dart';
import 'package:eld_management_system/features/hos/domain/repositories/hos_repository.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:eld_management_system/features/hos/domain/services/hos_calculator.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

/// Registers all dependencies (get_it + Riverpod providers layer on top).
Future<void> configureDependencies() async {
  if (sl.isRegistered<Dio>()) return;

  sl.registerLazySingleton<SecureStorageService>(SecureStorageService.create);
  sl.registerLazySingleton<DioClient>(
    () => DioClient(storage: sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<DriverRemoteDataSource>(
    () => DriverRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<ProfilePendingStore>(ProfilePendingStore.new);
  sl.registerLazySingleton<ProfileSyncService>(
    () => ProfileSyncService(
      remote: sl<DriverRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
      pending: sl<ProfilePendingStore>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
      profileSync: sl<ProfileSyncService>(),
      profilePending: sl<ProfilePendingStore>(),
    ),
  );

  sl.registerLazySingleton<LocationStore>(LocationStore.new);
  sl.registerLazySingleton<LocationOutboxStore>(LocationOutboxStore.new);
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<LocationSyncService>(
    () => LocationSyncService(
      outbox: sl<LocationOutboxStore>(),
      remote: sl<LocationRemoteDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<LocationTrailBuffer>(
    () => LocationTrailBuffer(
      outbox: sl<LocationOutboxStore>(),
      sync: sl<LocationSyncService>(),
    ),
  );
  sl.registerLazySingleton<LocationTrackingService>(
    () => LocationTrackingService(
      store: sl<LocationStore>(),
      trailBuffer: sl<LocationTrailBuffer>(),
    ),
  );

  sl.registerLazySingleton<NotificationPreferencesStore>(NotificationPreferencesStore.new);
  sl.registerLazySingleton<NotificationTapHandler>(NotificationTapHandler.new);
  sl.registerLazySingleton<NotificationService>(NotificationService.new);
  sl.registerLazySingleton<RemotePushTokenDataSource>(
    () => RemotePushTokenDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<RemotePushService>(
    () => RemotePushService(
      notifications: sl<NotificationService>(),
      tokenDataSource: sl<RemotePushTokenDataSource>(),
    ),
  );
  sl.registerLazySingleton<DriverNotificationDispatcher>(
    () => DriverNotificationDispatcher(sl<NotificationService>()),
  );

  sl.registerLazySingleton<GeometrisParser>(GeometrisParser.new);
  sl.registerLazySingleton<PermissionService>(PermissionService.new);
  sl.registerLazySingleton<EldLocalDataSource>(EldLocalDataSource.new);
  sl.registerLazySingleton<EldRemoteDataSource>(
    () => EldRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<EldOutboxStore>(EldOutboxStore.new);
  sl.registerLazySingleton<EldSyncService>(
    () => EldSyncService(
      outbox: sl<EldOutboxStore>(),
      remote: sl<EldRemoteDataSource>(),
      local: sl<EldLocalDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<EldTelemetryBuffer>(
    () => EldTelemetryBuffer(
      local: sl<EldLocalDataSource>(),
      outbox: sl<EldOutboxStore>(),
      sync: sl<EldSyncService>(),
      authLocal: sl<AuthLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton<BleDataSource>(
    () => BleDataSource(
      parser: sl<GeometrisParser>(),
      telemetryBuffer: sl<EldTelemetryBuffer>(),
    ),
  );
  sl.registerLazySingleton<EldRepository>(
    () => EldRepositoryImpl(
      sl<BleDataSource>(),
      sl<PermissionService>(),
      local: sl<EldLocalDataSource>(),
      sync: sl<EldSyncService>(),
    ),
  );

  sl.registerLazySingleton<HosLocalDataSource>(HosLocalDataSource.new);
  sl.registerLazySingleton<HosRemoteDataSource>(
    () => HosRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<HosOutboxStore>(HosOutboxStore.new);
  sl.registerLazySingleton<HosSyncService>(
    () => HosSyncService(
      outbox: sl<HosOutboxStore>(),
      remote: sl<HosRemoteDataSource>(),
      local: sl<HosLocalDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<HosCalculator>(HosCalculator.new);
  sl.registerLazySingleton<HosRepository>(
    () => HosRepositoryImpl(
      local: sl<HosLocalDataSource>(),
      calculator: sl<HosCalculator>(),
      outbox: sl<HosOutboxStore>(),
      sync: sl<HosSyncService>(),
      remote: sl<HosRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<FleetRemoteDataSource>(
    () => FleetRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<FleetRepository>(
    () => FleetRepositoryImpl(sl<FleetRemoteDataSource>()),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory<EldBloc>(() => EldBloc(sl<EldRepository>()));
}
