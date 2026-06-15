import 'dart:async';
import 'dart:io';

import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:eld_management_system/core/location/location_store.dart';
import 'package:eld_management_system/core/location/location_tracking_status.dart';
import 'package:eld_management_system/core/logging/app_logger.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_service.dart';
import 'package:eld_management_system/core/strings/location_strings.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// Foreground and background GPS tracking for FMCSA duty log positions.
class LocationTrackingService with WidgetsBindingObserver {
  LocationTrackingService({
    LocationStore? store,
    PermissionService? permissions,
  })  : _store = store ?? LocationStore(),
        _permissions = permissions ?? PermissionService();

  final LocationStore _store;
  final PermissionService _permissions;

  final _fixController = StreamController<LocationFix>.broadcast();
  final _statusController = StreamController<LocationTrackingStatus>.broadcast();

  StreamSubscription<Position>? _positionSub;
  String? _driverId;
  LocationFix? _lastFix;
  LocationFix? _lastPersistedFix;
  DateTime? _lastPersistedAt;
  LocationTrackingStatus _status = LocationTrackingStatus.idle;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  bool _observerRegistered = false;

  Stream<LocationFix> get fixStream => _fixController.stream;
  Stream<LocationTrackingStatus> get statusStream => _statusController.stream;
  LocationFix? get lastFix => _lastFix;
  LocationTrackingStatus get status => _status;

  void registerLifecycleObserver() {
    if (_observerRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _observerRegistered = true;
  }

  void unregisterLifecycleObserver() {
    if (!_observerRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _observerRegistered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (_driverId == null || _positionSub == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _setStatus(LocationTrackingStatus.trackingForeground);
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setStatus(LocationTrackingStatus.trackingBackground);
    }
  }

  Future<void> start({required String driverId}) async {
    if (_driverId == driverId && _positionSub != null) return;

    await stop();
    _driverId = driverId;
    registerLifecycleObserver();

    final cached = await _store.lastFix(driverId);
    if (cached != null) {
      _lastFix = cached;
      _fixController.add(cached);
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      _setStatus(LocationTrackingStatus.serviceDisabled);
      return;
    }

    if (!await _ensurePermissions()) {
      _setStatus(LocationTrackingStatus.permissionDenied);
      return;
    }

    final settings = _platformSettings();
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (Object e, StackTrace st) {
        AppLogger.error('Location position stream', e, st);
      },
    );

    _setStatus(
      _lifecycle == AppLifecycleState.resumed
          ? LocationTrackingStatus.trackingForeground
          : LocationTrackingStatus.trackingBackground,
    );
    AppLogger.info('Location tracking started for driver $driverId');
  }

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _driverId = null;
    _lastPersistedFix = null;
    _lastPersistedAt = null;
    _setStatus(LocationTrackingStatus.idle);
  }

  Future<void> dispose() async {
    unregisterLifecycleObserver();
    await stop();
    await _fixController.close();
    await _statusController.close();
  }

  Future<bool> _ensurePermissions() async {
    await _permissions.requestOne(EldPermissionKind.locationWhenInUse);
    await _permissions.requestOne(EldPermissionKind.locationAlways);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationSettings _platformSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: LocationStrings.foregroundNotificationTitle,
          notificationText: LocationStrings.foregroundNotificationBody,
          notificationChannelName: LocationStrings.foregroundChannelName,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          setOngoing: true,
          enableWakeLock: true,
        ),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }

  void _onPosition(Position position) {
    final driverId = _driverId;
    if (driverId == null) return;

    final fix = LocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracyMeters: position.accuracy,
      speedMps: position.speed,
      heading: position.heading,
    );

    _lastFix = fix;
    _fixController.add(fix);

    if (_shouldPersist(fix)) {
      _lastPersistedFix = fix;
      _lastPersistedAt = fix.timestamp;
      unawaited(_store.saveFix(driverId: driverId, fix: fix));
    }
  }

  bool _shouldPersist(LocationFix fix) {
    final last = _lastPersistedFix;
    final lastAt = _lastPersistedAt;
    if (last == null || lastAt == null) return true;

    final elapsed = fix.timestamp.difference(lastAt);
    if (elapsed >= const Duration(seconds: 60)) return true;

    final distance = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      fix.latitude,
      fix.longitude,
    );
    return distance >= 25;
  }

  void _setStatus(LocationTrackingStatus status) {
    if (_status == status) return;
    _status = status;
    _statusController.add(status);
  }
}