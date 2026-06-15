/// FMCSA 49 CFR 395 duty statuses.
enum DutyStatus {
  driving('D'),
  onDutyNotDriving('ON'),
  offDuty('OFF'),
  sleeperBerth('SB');

  const DutyStatus(this.code);
  final String code;

  static DutyStatus fromCode(String code) {
    return DutyStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => DutyStatus.offDuty,
    );
  }

  String get displayName {
    switch (this) {
      case DutyStatus.driving:
        return 'Driving';
      case DutyStatus.onDutyNotDriving:
        return 'On Duty (Not Driving)';
      case DutyStatus.offDuty:
        return 'Off Duty';
      case DutyStatus.sleeperBerth:
        return 'Sleeper Berth';
    }
  }
}