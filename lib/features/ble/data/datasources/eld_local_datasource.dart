import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/ble/data/mappers/eld_telemetry_mapper.dart';
import 'package:eld_management_system/features/ble/domain/entities/eld_telemetry_record.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EldLocalDataSource {
  Future<Box<String>> _box() => Hive.openBox<String>(AppConstants.hiveBoxEld);

  Future<void> append(EldTelemetryRecord record) async {
    final box = await _box();
    await box.put(record.id, jsonEncode(EldTelemetryMapper.toLocalJson(record)));
    await _trim(box);
  }

  Future<List<EldTelemetryRecord>> listRecent({int limit = 5000}) async {
    final box = await _box();
    final records = <EldTelemetryRecord>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      records.add(
        EldTelemetryMapper.fromLocalJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    }
    records.sort((a, b) => b.data.timestamp.compareTo(a.data.timestamp));
    if (records.length > limit) {
      return records.take(limit).toList();
    }
    return records;
  }

  Future<void> removeMany(Iterable<String> ids) async {
    final box = await _box();
    for (final id in ids) {
      await box.delete(id);
    }
  }

  Future<void> _trim(Box<String> box) async {
    if (box.length <= 5000) return;
    final records = <EldTelemetryRecord>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      records.add(
        EldTelemetryMapper.fromLocalJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    }
    records.sort((a, b) => b.data.timestamp.compareTo(a.data.timestamp));
    final keep = records.take(5000).map((r) => r.id).toSet();
    for (final key in box.keys) {
      if (!keep.contains(key)) {
        await box.delete(key);
      }
    }
  }
}