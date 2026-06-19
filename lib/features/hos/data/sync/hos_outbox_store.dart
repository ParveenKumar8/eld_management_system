import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/hos/data/mappers/hos_record_mapper.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HosOutboxEntry {
  const HosOutboxEntry({
    required this.recordId,
    required this.record,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
  });

  final String recordId;
  final HosRecord record;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;

  HosOutboxEntry copyWith({
    int? attempts,
    String? lastError,
  }) {
    return HosOutboxEntry(
      recordId: recordId,
      record: record,
      queuedAt: queuedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Offline-first queue for HOS records awaiting server sync.
class HosOutboxStore {
  Future<Box<String>> _box() => Hive.openBox<String>(AppConstants.hiveBoxHosOutbox);

  Future<void> enqueue(HosRecord record) async {
    final box = await _box();
    final entry = HosOutboxEntry(
      recordId: record.id,
      record: record,
      queuedAt: DateTime.now().toUtc(),
    );
    await box.put(record.id, _encode(entry));
  }

  Future<List<HosOutboxEntry>> pending() async {
    final box = await _box();
    final entries = <HosOutboxEntry>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      entries.add(_decode(raw));
    }
    entries.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return entries;
  }

  Future<void> removeMany(Iterable<String> recordIds) async {
    final box = await _box();
    for (final id in recordIds) {
      await box.delete(id);
    }
  }

  Future<void> markAttempt({
    required String recordId,
    required String error,
  }) async {
    final box = await _box();
    final raw = box.get(recordId);
    if (raw == null) return;
    final entry = _decode(raw).copyWith(
      attempts: _decode(raw).attempts + 1,
      lastError: error,
    );
    await box.put(recordId, _encode(entry));
  }

  String _encode(HosOutboxEntry entry) => jsonEncode({
        'record_id': entry.recordId,
        'queued_at': entry.queuedAt.toIso8601String(),
        'attempts': entry.attempts,
        'last_error': entry.lastError,
        'record': HosRecordMapper.toApiJson(entry.record),
      });

  HosOutboxEntry _decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return HosOutboxEntry(
      recordId: map['record_id'] as String,
      queuedAt: DateTime.parse(map['queued_at'] as String),
      attempts: map['attempts'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      record: HosRecordMapper.fromApiJson(map['record'] as Map<String, dynamic>),
    );
  }
}