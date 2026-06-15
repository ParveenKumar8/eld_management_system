/// Role-based access for fleet operations (extensible).
enum UserRole {
  driver('driver'),
  fleetManager('fleet_manager'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.driver,
    );
  }

  bool canManageFleet() => this == UserRole.fleetManager || this == UserRole.admin;
  bool canEditCertifiedLogs() => this == UserRole.admin;
}