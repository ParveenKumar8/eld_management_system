import 'dart:async';

import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/core/notifications/driver_notification_dispatcher.dart';
import 'package:eld_management_system/core/notifications/notification_service.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:eld_management_system/features/hos/domain/repositories/hos_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Listens to ELD/HOS events and dispatches essential driver notifications.
class NotificationBridge extends StatefulWidget {
  const NotificationBridge({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationBridge> createState() => _NotificationBridgeState();
}

class _NotificationBridgeState extends State<NotificationBridge> {
  static const _hosPollInterval = Duration(minutes: 5);

  late final DriverNotificationDispatcher _dispatcher;
  late final HosRepository _hosRepository;
  late final NotificationService _notifications;
  Timer? _hosPollTimer;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _dispatcher = sl<DriverNotificationDispatcher>();
    _hosRepository = sl<HosRepository>();
    _notifications = sl<NotificationService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onAuthState(context.read<AuthBloc>().state);
    });
  }

  @override
  void dispose() {
    _hosPollTimer?.cancel();
    super.dispose();
  }

  void _onAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      _driverId = state.user.id;
      _startHosPolling();
      _pollHosSummary();
      return;
    }

    _driverId = null;
    _hosPollTimer?.cancel();
    _hosPollTimer = null;
  }

  void _startHosPolling() {
    _hosPollTimer?.cancel();
    _hosPollTimer = Timer.periodic(_hosPollInterval, (_) => _pollHosSummary());
  }

  Future<void> _pollHosSummary() async {
    final driverId = _driverId;
    if (driverId == null) return;
    if (!await _notifications.areAlertsEnabled()) return;

    final result = await _hosRepository.getSummary(driverId);
    result.fold((_) {}, _dispatcher.onHosSummary);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType ||
              (current is AuthAuthenticated &&
                  previous is AuthAuthenticated &&
                  previous.user.id != current.user.id),
          listener: (_, state) => _onAuthState(state),
        ),
        BlocListener<EldBloc, EldState>(
          listenWhen: (previous, current) =>
              previous.connectionState != current.connectionState ||
              previous.scanPhase != current.scanPhase ||
              current is EldError,
          listener: (_, state) => _dispatcher.onEldState(state),
        ),
      ],
      child: widget.child,
    );
  }
}