import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:eld_management_system/core/permissions/permission_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionCatalog', () {
    test('iconFor covers every permission kind', () {
      for (final kind in EldPermissionKind.values) {
        expect(PermissionCatalog.iconFor(kind), isNotNull);
      }
    });

    test('applicableItems returns a list on host platform', () async {
      final items = await PermissionCatalog.applicableItems();
      expect(items, isA<List>());
    });
  });
}