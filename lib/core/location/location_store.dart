import 'dart:convert';

import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/core/location/location_fix.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists the latest GPS fix and a rolling location trail per driver.
class LocationStore {
  static const _lastFixKeyPrefix = 'last_fix_';
  static const _trailKeyPrefix = 'trail_';

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(AppConstants.hiveBoxLocation)) {
      return Hive.box<String>(AppConstants.hiveBoxLocation);
    }
    return Hive.openBox<String>(AppConstants.hiveBoxLocation);
  }

  Future<LocationFix?> lastFix(String driverId) async {
    final box = await _box();
    final json = box.get('$_lastFixKeyPrefix$driverId');
    if (json == null) return null;
    return LocationFix.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveFix({
    required String driverId,
    required LocationFix fix,
    bool appendTrail = true,
  }) async {
    final box = await _box();
    await box.put('$_lastFixKeyPrefix$driverId', jsonEncode(fix.toJson()));

    if (!appendTrail) return;

    final trailKey = '$_trailKeyPrefix$driverId';
    final existing = box.get(trailKey);
    final trail = existing == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(existing) as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

    trail.add(fix.toJson());
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 8));
    final pruned = trail.where((entry) {
      final ts = DateTime.parse(entry['timestamp'] as String);
      return !ts.isBefore(cutoff);
    }).toList();

    await box.put(trailKey, jsonEncode(pruned));
  }
}