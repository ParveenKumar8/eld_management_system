import 'package:eld_management_system/core/di/providers.dart';
import 'package:eld_management_system/core/theme/app_theme.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/ble/presentation/widgets/ble_connection_overlay.dart';
import 'package:eld_management_system/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EldApp extends ConsumerStatefulWidget {
  const EldApp({required this.authBloc, super.key});

  final AuthBloc authBloc;

  @override
  ConsumerState<EldApp> createState() => _EldAppState();
}

class _EldAppState extends ConsumerState<EldApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.authBloc);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.authBloc),
        BlocProvider(
          create: (_) => ref.read(eldBlocProvider),
        ),
      ],
      child: MaterialApp.router(
        title: 'ELD Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: switch (themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        },
        routerConfig: _router,
        builder: (context, child) => BleConnectionOverlay(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}