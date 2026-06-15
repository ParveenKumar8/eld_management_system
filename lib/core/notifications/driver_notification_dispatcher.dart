import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/notifications/driver_notification_type.dart';
import 'package:eld_management_system/core/notifications/notification_service.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_device.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_summary.dart';

/// Maps ELD/HOS app events to essential driver notifications.
class DriverNotificationDispatcher {
  DriverNotificationDispatcher(this._notifications);

  final NotificationService _notifications;

  EldConnectionState? _lastConnectionState;
  EldScanPhase? _lastScanPhase;
  final Set<DriverNotificationType> _hosWarningsSent = {};

  Future<void> onEldState(EldState state) async {
    await _handleConnectionChange(state.connectionState);
    await _handleScanCompletion(state);
    await _handleEldError(state);
  }

  Future<void> onHosSummary(HosSummary summary) async {
    if (summary.isInViolation && summary.violationMessage != null) {
      await _notifyOnce(
        DriverNotificationType.hosViolation,
        detail: summary.violationMessage,
      );
      return;
    }

    if (summary.remainingDriveMinutes <= 60 && summary.remainingDriveMinutes > 0) {
      await _notifyOnce(
        DriverNotificationType.hosDriveLimitWarning,
        detail: '${summary.remainingDriveMinutes} min remaining.',
      );
    }

    if (summary.remainingOnDutyMinutes <= 60 && summary.remainingOnDutyMinutes > 0) {
      await _notifyOnce(
        DriverNotificationType.hosOnDutyLimitWarning,
        detail: '${summary.remainingOnDutyMinutes} min remaining.',
      );
    }

    if (summary.remainingCycleMinutes <= 120 && summary.remainingCycleMinutes > 0) {
      await _notifyOnce(
        DriverNotificationType.hosCycleLimitWarning,
        detail: '${summary.remainingCycleMinutes} min left in cycle.',
      );
    }

    final restRemaining = AppConstants.requiredOffDutyMinutes - summary.offDutyMinutesSinceLastReset;
    if (restRemaining > 0 && restRemaining <= 120) {
      await _notifyOnce(
        DriverNotificationType.hosBreakRequired,
        detail: '${restRemaining ~/ 60}h rest still needed.',
      );
    }
  }

  void resetHosWarnings() => _hosWarningsSent.clear();

  Future<void> _handleConnectionChange(EldConnectionState current) async {
    final previous = _lastConnectionState;
    _lastConnectionState = current;
    if (previous == null) return;

    if (previous == EldConnectionState.connected && current == EldConnectionState.disconnected) {
      await _notifications.show(DriverNotificationType.eldDisconnected);
      return;
    }

    if (current == EldConnectionState.connected && previous != EldConnectionState.connected) {
      await _notifications.show(DriverNotificationType.eldConnected);
      return;
    }

    if (current == EldConnectionState.reconnecting) {
      await _notifications.show(DriverNotificationType.eldReconnecting);
      return;
    }

    if (current == EldConnectionState.error) {
      await _notifications.show(DriverNotificationType.eldConnectionError);
    }
  }

  Future<void> _handleScanCompletion(EldState state) async {
    final previous = _lastScanPhase;
    _lastScanPhase = state.scanPhase;
    if (previous != EldScanPhase.scanning || state.scanPhase != EldScanPhase.completed) {
      return;
    }

    if (state.devices.isEmpty) {
      await _notifications.show(DriverNotificationType.eldScanEmpty);
      return;
    }

    await _notifications.show(
      DriverNotificationType.eldScanComplete,
      detail: '${state.devices.length} device(s) found.',
    );
  }

  Future<void> _handleEldError(EldState state) async {
    if (state is! EldError) return;
    if (state.message.toLowerCase().contains('eld-compatible') ||
        state.message.toLowerCase().contains('not eld')) {
      await _notifications.show(DriverNotificationType.eldIncompatibleDevice);
    }
  }

  Future<void> _notifyOnce(DriverNotificationType type, {String? detail}) async {
    if (_hosWarningsSent.contains(type)) return;
    _hosWarningsSent.add(type);
    await _notifications.show(type, detail: detail);
  }
}