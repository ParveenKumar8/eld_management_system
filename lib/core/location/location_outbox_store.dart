import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/location/location_trail_mapper.dart';
import 'package:eld_management_system/core/location/location_trail_point.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocationOutboxEntry {
  const LocationOutboxEntry({
    required this.pointId,
    required this.point,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
  });

  final String pointId;
  final LocationTrailPoint point;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;

  LocationOutboxEntry copyWith({int? attempts, String? lastError}) => LocationOutboxEntry(
        pointId: pointId,
        point: point,
        queuedAt: queuedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );
}

class LocationOutboxStore {
  Future<Box<String>> _box() => Hive.openBox<String>(AppConstants.hiveBoxLocationOutbox);

  Future<void> enqueue(LocationTrailPoint point) async {
    final box = await _box();
    final entry = LocationOutboxEntry(
      pointId: point.id,
      point: point,
      queuedAt: DateTime.now().toUtc(),
    );
    await box.put(point.id, _encode(entry));
  }

  Future<List<LocationOutboxEntry>> pending({int batchSize = 200}) async {
    final box = await _box();
    final entries = <LocationOutboxEntry>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      entries.add(_decode(raw));
    }
    entries.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    if (entries.length <= batchSize) return entries;
    return entries.take(batchSize).toList();
  }

  Future<void> removeMany(Iterable<String> pointIds) async {
    final box = await _box();
    for (final id in pointIds) {
      await box.delete(id);
    }
  }

  Future<void> markAttempt({required String pointId, required String error}) async {
    final box = await _box();
    final raw = box.get(pointId);
    if (raw == null) return;
    final entry = _decode(raw).copyWith(
      attempts: _decode(raw).attempts + 1,
      lastError: error,
    );
    await box.put(pointId, _encode(entry));
  }

  String _encode(LocationOutboxEntry entry) => jsonEncode({
        'point_id': entry.pointId,
        'queued_at': entry.queuedAt.toIso8601String(),
        'attempts': entry.attempts,
        'last_error': entry.lastError,
        'point': LocationTrailMapper.toApiJson(entry.point),
      });

  LocationOutboxEntry _decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return LocationOutboxEntry(
      pointId: map['point_id'] as String,
      queuedAt: DateTime.parse(map['queued_at'] as String),
      attempts: map['attempts'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      point: LocationTrailMapper.fromApiJson(map['point'] as Map<String, dynamic>),
    );
  }
}