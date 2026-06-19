import 'package:eld_management_system/core/constants/app_constants.dart';
import 'package:eld_management_system/features/auth/data/sync/profile_pending_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late ProfilePendingStore store;

  setUp(() async {
    Hive.init('test_profile_pending');
    await Hive.openBox<String>(AppConstants.hiveBoxProfilePending);
    store = ProfilePendingStore();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxProfilePending);
  });

  test('stores and clears pending profile updates', () async {
    await store.save(displayName: 'Updated Name', licenseNumber: 'CDL-999');
    final pending = await store.get();

    expect(pending?.displayName, 'Updated Name');
    expect(pending?.licenseNumber, 'CDL-999');

    await store.clear();
    expect(await store.get(), isNull);
  });
}