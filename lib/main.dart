import 'package:eld_management_system/app.dart';
import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/core/notifications/notification_service.dart';
import 'package:eld_management_system/core/notifications/notification_tap_handler.dart';
import 'package:eld_management_system/core/notifications/remote_push_service.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/features/background/background_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await configureDependencies();
    final tapHandler = sl<NotificationTapHandler>();
    await sl<NotificationService>().initialize(
      onTap: tapHandler.handleRawPayload,
    );
    await sl<RemotePushService>().initialize(
      onTap: tapHandler.handleRemote,
    );
    await BackgroundService.initialize();
    AppLogger.info('ELD Management System started');
  } catch (e, st) {
    AppLogger.reportCrash(e, st, hint: 'Startup failure');
  }

  final authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());

  runApp(
    ProviderScope(
      child: EldApp(authBloc: authBloc),
    ),
  );
}