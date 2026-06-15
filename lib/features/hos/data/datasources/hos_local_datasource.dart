import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/hos/domain/entities/duty_status.dart';
import 'package:eld_management_system/features/hos/domain/entities/hos_record.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class HosLocalDataSource {
  final _uuid = const Uuid();

  Future<Box<String>> _box() => Hive.openBox<String>(AppConstants.hiveBoxHos);

  Future<List<HosRecord>> getRecords({String? driverId, int days = 8}) async {
    final box = await _box();
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    final records = <HosRecord>[];

    for (final key in box.keys) {
      final json = box.get(key);
      if (json == null) continue;
      final record = _fromJson(json);
      if (driverId != null && record.driverId != driverId) continue;
      if (record.startTime.isBefore(cutoff)) continue;
      records.add(record);
    }
    records.sort((a, b) => b.startTime.compareTo(a.startTime));
    return records;
  }

  Future<HosRecord> insertRecord(HosRecord record) async {
    final box = await _box();
    await box.put(record.id, _toJson(record));
    return record;
  }

  Future<void> closeActiveRecord(String driverId) async {
    final records = await getRecords(driverId: driverId, days: 2);
    final active = records.where((r) => r.endTime == null).toList();
    for (final r in active) {
      await insertRecord(r.copyWith(endTime: DateTime.now().toUtc()));
    }
  }

  Future<HosRecord> createDutyChange({
    required String driverId,
    required DutyStatus status,
    String? annotation,
    double? lat,
    double? lng,
    String? vehicleId,
  }) async {
    await closeActiveRecord(driverId);
    final record = HosRecord(
      id: _uuid.v4(),
      driverId: driverId,
      status: status,
      startTime: DateTime.now().toUtc(),
      annotation: annotation,
      locationLat: lat,
      locationLng: lng,
      vehicleId: vehicleId,
    );
    return insertRecord(record);
  }

  Future<String> exportJson({required String driverId, required int days}) async {
    final records = await getRecords(driverId: driverId, days: days);
    final payload = {
      'driver_id': driverId,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'fmcsa_format': 'ELD_OUTPUT_FILE',
      'records': records.map(_recordToMap).toList(),
    };
    return jsonEncode(payload);
  }

  Map<String, dynamic> _recordToMap(HosRecord r) => {
        'id': r.id,
        'status': r.status.code,
        'start': r.startTime.toIso8601String(),
        'end': r.endTime?.toIso8601String(),
        'annotation': r.annotation,
        'lat': r.locationLat,
        'lng': r.locationLng,
        'edited': r.isEdited,
        'certified_at': r.certifiedAt?.toIso8601String(),
      };

  String _toJson(HosRecord r) => jsonEncode(_recordToMap(r));

  HosRecord _fromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return HosRecord(
      id: m['id'] as String,
      driverId: m['driver_id'] as String? ?? m['driverId'] as String,
      status: DutyStatus.fromCode(m['status'] as String),
      startTime: DateTime.parse(m['start'] as String),
      endTime: m['end'] != null ? DateTime.parse(m['end'] as String) : null,
      annotation: m['annotation'] as String?,
      locationLat: (m['lat'] as num?)?.toDouble(),
      locationLng: (m['lng'] as num?)?.toDouble(),
      isEdited: m['edited'] as bool? ?? false,
      certifiedAt: m['certified_at'] != null
          ? DateTime.parse(m['certified_at'] as String)
          : null,
      vehicleId: m['vehicle_id'] as String?,
    );
  }
}