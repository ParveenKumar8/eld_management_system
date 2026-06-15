import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/core/location/location_tracking_service.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Starts and stops GPS tracking based on authentication state.
class LocationTrackingBridge extends StatefulWidget {
  const LocationTrackingBridge({required this.child, super.key});

  final Widget child;

  @override
  State<LocationTrackingBridge> createState() => _LocationTrackingBridgeState();
}

class _LocationTrackingBridgeState extends State<LocationTrackingBridge> {
  late final LocationTrackingService _tracking;

  @override
  void initState() {
    super.initState();
    _tracking = sl<LocationTrackingService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onAuthState(context.read<AuthBloc>().state);
    });
  }

  Future<void> _onAuthState(AuthState state) async {
    if (state is AuthAuthenticated) {
      await _tracking.start(driverId: state.user.id);
      return;
    }
    await _tracking.stop();
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