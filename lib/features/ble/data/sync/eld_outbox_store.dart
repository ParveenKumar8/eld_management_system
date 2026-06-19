import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/ble/data/mappers/eld_telemetry_mapper.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EldOutboxEntry {
  const EldOutboxEntry({
    required this.eventId,
    required this.record,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
  });

  final String eventId;
  final EldTelemetryRecord record;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;

  EldOutboxEntry copyWith({int? attempts, String? lastError}) => EldOutboxEntry(
        eventId: eventId,
        record: record,
        queuedAt: queuedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );
}

class EldOutboxStore {
  Future<Box<String>> _box() => Hive.openBox<String>(AppConstants.hiveBoxEldOutbox);

  Future<void> enqueue(EldTelemetryRecord record) async {
    final box = await _box();
    final entry = EldOutboxEntry(
      eventId: record.id,
      record: record,
      queuedAt: DateTime.now().toUtc(),
    );
    await box.put(record.id, _encode(entry));
  }

  Future<List<EldOutboxEntry>> pending({int batchSize = 200}) async {
    final box = await _box();
    final entries = <EldOutboxEntry>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      entries.add(_decode(raw));
    }
    entries.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    if (entries.length <= batchSize) return entries;
    return entries.take(batchSize).toList();
  }

  Future<void> removeMany(Iterable<String> eventIds) async {
    final box = await _box();
    for (final id in eventIds) {
      await box.delete(id);
    }
  }

  Future<void> markAttempt({required String eventId, required String error}) async {
    final box = await _box();
    final raw = box.get(eventId);
    if (raw == null) return;
    final entry = _decode(raw).copyWith(
      attempts: _decode(raw).attempts + 1,
      lastError: error,
    );
    await box.put(eventId, _encode(entry));
  }

  String _encode(EldOutboxEntry entry) => jsonEncode({
        'event_id': entry.eventId,
        'queued_at': entry.queuedAt.toIso8601String(),
        'attempts': entry.attempts,
        'last_error': entry.lastError,
        'record': EldTelemetryMapper.toApiJson(entry.record),
      });

  EldOutboxEntry _decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return EldOutboxEntry(
      eventId: map['event_id'] as String,
      queuedAt: DateTime.parse(map['queued_at'] as String),
      attempts: map['attempts'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      record: EldTelemetryMapper.fromApiJson(map['record'] as Map<String, dynamic>),
    );
  }
}