import 'package:dio/dio.dart';
import 'package:eld_management_system/core/network/dio_client.dart';
import 'package:eld_management_system/core/location/location_store.dart';
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
import 'package:eld_management_system/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:eld_management_system/features/ble/data/datasources/ble_datasource.dart';
import 'package:eld_management_system/features/ble/data/parsers/geometris_parser.dart';
import 'package:eld_management_system/features/ble/data/repositories/eld_repository_impl.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';
import 'package:eld_management_system/features/hos/data/datasources/hos_local_datasource.dart';
import 'package:eld_management_system/features/hos/data/repositories/hos_repository_impl.dart';
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
  sl.registerLazySingleton<DioClient>(DioClient.new);
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<Dio>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<LocationStore>(LocationStore.new);
  sl.registerLazySingleton<LocationTrackingService>(LocationTrackingService.new);

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
  sl.registerLazySingleton<BleDataSource>(
    () => BleDataSource(parser: sl<GeometrisParser>()),
  );
  sl.registerLazySingleton<EldRepository>(
    () => EldRepositoryImpl(sl<BleDataSource>(), sl<PermissionService>()),
  );

  sl.registerLazySingleton<HosLocalDataSource>(HosLocalDataSource.new);
  sl.registerLazySingleton<HosCalculator>(HosCalculator.new);
  sl.registerLazySingleton<HosRepository>(
    () => HosRepositoryImpl(
      local: sl<HosLocalDataSource>(),
      calculator: sl<HosCalculator>(),
    ),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory<EldBloc>(() => EldBloc(sl<EldRepository>()));
}
