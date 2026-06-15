import 'dart:async';

import 'package:eld_management_system/core/theme/app_colors.dart';
import 'package:eld_management_system/core/theme/app_spacing.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

/// Full-screen Lottie overlay during BLE connect / success.
class BleConnectionOverlay extends StatefulWidget {
  const BleConnectionOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<BleConnectionOverlay> createState() => _BleConnectionOverlayState();
}

class _BleConnectionOverlayState extends State<BleConnectionOverlay> {
  bool _visible = false;
  String _message = 'Connecting to ELD…';
  bool _success = false;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onState(EldState state) {
    if (state.connectionState == EldConnectionState.connecting ||
        state.connectionState == EldConnectionState.reconnecting) {
      _dismissTimer?.cancel();
      setState(() {
        _visible = true;
        _success = false;
        _message = state.connectionState == EldConnectionState.reconnecting
            ? 'Reconnecting to ELD…'
            : 'Connecting to ELD…';
      });
    } else if (state.connectionState == EldConnectionState.connected) {
      setState(() {
        _visible = true;
        _success = true;
        _message = 'ELD Connected';
      });
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _visible = false);
      });
    } else if (state.connectionState == EldConnectionState.error) {
      setState(() {
        _visible = true;
        _success = false;
        _message = 'Connection failed';
      });
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(milliseconds: 2200), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EldBloc, EldState>(
      listenWhen: (prev, curr) => prev.connectionState != curr.connectionState,
      listener: (_, state) => _onState(state),
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              child: _visible
                  ? Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Center(
                        child: AnimatedScale(
                          scale: _visible ? 1 : 0.9,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          child: Container(
                            margin: const EdgeInsets.all(AppSpacing.xl),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 32,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: _success
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          size: 100,
                                          color: AppColors.success,
                                        )
                                      : Lottie.asset(
                                          'assets/animations/ble_connect.json',
                                          fit: BoxFit.contain,
                                          repeat: true,
                                        ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _message,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}