import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eld_management_system/core/permissions/eld_permission_kind.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Describes which permissions apply on the current platform and how to resolve them.
class PermissionCatalogItem {
  const PermissionCatalogItem({
    required this.kind,
    required this.required,
    required this.permissions,
    this.icon = Icons.security_rounded,
  });

  final EldPermissionKind kind;
  final bool required;
  final List<Permission> permissions;
  final IconData icon;
}

/// Builds the platform-specific permission list so UI and service stay in sync.
abstract final class PermissionCatalog {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static int? _cachedAndroidSdk;

  static Future<int> androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    _cachedAndroidSdk ??= (await _deviceInfo.androidInfo).version.sdkInt;
    return _cachedAndroidSdk!;
  }

  static Future<List<PermissionCatalogItem>> applicableItems() async {
    if (Platform.isAndroid) {
      return _androidItems(await androidSdkInt());
    }
    if (Platform.isIOS) {
      return _iosItems();
    }
    return const [];
  }

  static List<PermissionCatalogItem> _iosItems() {
    return const [
      PermissionCatalogItem(
        kind: EldPermissionKind.bluetooth,
        required: true,
        permissions: [Permission.bluetooth],
        icon: Icons.bluetooth_rounded,
      ),
      PermissionCatalogItem(
        kind: EldPermissionKind.locationWhenInUse,
        required: true,
        permissions: [Permission.locationWhenInUse],
        icon: Icons.location_on_outlined,
      ),
      PermissionCatalogItem(
        kind: EldPermissionKind.locationAlways,
        required: false,
        permissions: [Permission.locationAlways],
        icon: Icons.my_location_rounded,
      ),
    ];
  }

  static List<PermissionCatalogItem> _androidItems(int sdkInt) {
    final bluetoothPermissions = sdkInt >= 31
        ? const [Permission.bluetoothScan, Permission.bluetoothConnect]
        : const [Permission.bluetooth, Permission.location];

    final items = <PermissionCatalogItem>[
      PermissionCatalogItem(
        kind: EldPermissionKind.bluetooth,
        required: true,
        permissions: bluetoothPermissions,
        icon: Icons.bluetooth_rounded,
      ),
    ];

    if (sdkInt >= 31) {
      items.add(
        const PermissionCatalogItem(
          kind: EldPermissionKind.locationWhenInUse,
          required: true,
          permissions: [Permission.locationWhenInUse],
          icon: Icons.location_on_outlined,
        ),
      );
    }

    items.addAll(const [
      PermissionCatalogItem(
        kind: EldPermissionKind.locationAlways,
        required: false,
        permissions: [Permission.locationAlways],
        icon: Icons.my_location_rounded,
      ),
    ]);

    if (sdkInt >= 33) {
      items.add(
        const PermissionCatalogItem(
          kind: EldPermissionKind.notification,
          required: true,
          permissions: [Permission.notification],
          icon: Icons.notifications_outlined,
        ),
      );
    }

    return items;
  }

  static IconData iconFor(EldPermissionKind kind) {
    return switch (kind) {
      EldPermissionKind.bluetooth => Icons.bluetooth_rounded,
      EldPermissionKind.locationWhenInUse => Icons.location_on_outlined,
      EldPermissionKind.locationAlways => Icons.my_location_rounded,
      EldPermissionKind.notification => Icons.notifications_outlined,
    };
  }
}