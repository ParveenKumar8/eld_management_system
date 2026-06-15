import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/strings/permission_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionStrings', () {
    test('maps titles and rationales for every permission kind', () {
      for (final kind in EldPermissionKind.values) {
        expect(PermissionStrings.titleFor(kind), isNotEmpty);
        expect(PermissionStrings.rationaleFor(kind), isNotEmpty);
      }
    });

    test('builds denied summary from labels', () {
      expect(
        PermissionStrings.deniedSummary(['Bluetooth', 'Location while using app']),
        '${PermissionStrings.deniedSummaryPrefix}: Bluetooth, Location while using app',
      );
    });

    test('maps display statuses to labels', () {
      for (final status in AppPermissionDisplayStatus.values) {
        expect(PermissionStrings.statusLabel(status), isNotEmpty);
      }
    });
  });
}