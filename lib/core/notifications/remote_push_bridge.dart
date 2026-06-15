import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/core/notifications/remote_push_service.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Registers FCM tokens when authenticated and unregisters on sign-out.
class RemotePushBridge extends StatefulWidget {
  const RemotePushBridge({required this.child, super.key});

  final Widget child;

  @override
  State<RemotePushBridge> createState() => _RemotePushBridgeState();
}

class _RemotePushBridgeState extends State<RemotePushBridge> {
  late final RemotePushService _remotePush;

  @override
  void initState() {
    super.initState();
    _remotePush = sl<RemotePushService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onAuthState(context.read<AuthBloc>().state);
    });
  }

  Future<void> _onAuthState(AuthState state) async {
    if (state is AuthAuthenticated) {
      await _remotePush.bindDriver(state.user.id);
      return;
    }
    await _remotePush.unbindDriver();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (current is AuthAuthenticated &&
              previous is AuthAuthenticated &&
              previous.user.id != current.user.id),
      listener: (_, state) => _onAuthState(state),
      child: widget.child,
    );
  }
}