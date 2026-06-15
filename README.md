# ELD Management System

Enterprise-grade Flutter application for US trucking fleets — FMCSA-compliant Electronic Logging Device (ELD) management with Bluetooth ELD integration, Hours of Service (HOS) tracking, and fleet role-based access.

## Requirements

- **Flutter 3.24+** (stable channel recommended; CI uses 3.24.0)
- Xcode 15+ (iOS) / Android Studio with SDK 34+ (Android)
- Physical device recommended for BLE testing

## Quick Start

```bash
cd eld_management_system
flutter pub get
flutter run
```

### Environment

| Variable | Description |
|----------|-------------|
| `API_BASE_URL` | Backend API base URL (default: demo endpoint) |

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.com/v1
```

### Social Auth Setup

- **Google**: Add `google-services.json` (Android) and URL schemes (iOS)
- **Facebook**: Configure `flutter_facebook_auth` app ID in native projects
- **Apple (iOS only)**: Enable Sign in with Apple capability in Xcode

## Architecture

Clean Architecture with feature-first modules:

```
lib/
├── core/           # DI, network, theme, errors, logging, security
├── features/
│   ├── auth/       # Email, Google, Facebook, Apple sign-in
│   ├── ble/        # flutter_blue_plus, Geometris parser
│   ├── hos/        # FMCSA HOS engine & local persistence
│   ├── dashboard/
│   ├── devices/
│   ├── logs/
│   ├── reports/
│   ├── profile/
│   ├── settings/
│   └── background/ # WorkManager sync tasks
├── router/         # GoRouter + auth redirects
└── l10n/           # English (US), extensible ARB
```

### Layer Diagram

```
┌─────────────────────────────────────────────────────────┐
│  Presentation (Riverpod + Bloc/Cubit + Material 3 UI)   │
├─────────────────────────────────────────────────────────┤
│  Domain (Entities, Use Cases, Repository Interfaces)    │
├─────────────────────────────────────────────────────────┤
│  Data (Remote API, Hive, BLE, Secure Storage)           │
└─────────────────────────────────────────────────────────┘
```

### State Management

| Concern | Tool |
|---------|------|
| DI & global providers | `get_it` + `flutter_riverpod` |
| Auth flow | `AuthBloc` |
| BLE scan/connect | `EldBloc` |
| HOS records | `HosCubit` |
| Navigation | `go_router` |

### SOLID Highlights

- **S**: Single-purpose use cases (`SignInWithEmail`, `HosCalculator`)
- **O**: Extensible `UserRole`, `DutyStatus` without modifying consumers
- **L**: Repository implementations substitutable for mocks in tests
- **I**: Narrow repository interfaces per feature
- **D**: Presentation depends on domain abstractions, not Dio/BLE directly

## Core Features

### Authentication
- Email/password login & registration
- Google, Facebook, Apple (iOS) social login
- `flutter_secure_storage` for tokens
- Roles: Driver, Fleet Manager, Admin

### Bluetooth ELD
- Permissions: Bluetooth, Location (always), Nearby Devices (Android 12+)
- Scan/filter Geometris Whereqube-compatible devices
- BLE connect via `flutter_blue_plus`
- `GeometrisParser` — Dart port of GeometrisMobile parsing
- Auto-reconnect with exponential backoff

### HOS (FMCSA)
- Duty statuses: Driving, On Duty, Off Duty, Sleeper Berth
- 11-hour drive / 14-hour window / 60-hour cycle calculations
- Annotations on status changes
- Malfunction/diagnostic logging hooks
- JSON export for roadside inspection

### Background
- `workmanager` periodic sync (15 min)
- Android manifest: foreground service type `connectedDevice` ready
- iOS: `bluetooth-central`, `location`, `fetch` background modes

## Testing

```bash
flutter test
flutter test integration_test/app_test.dart
```

| Test | Coverage |
|------|----------|
| `hos_calculator_test.dart` | FMCSA limit math, violations |
| `geometris_parser_test.dart` | BLE payload parsing |
| `auth_bloc_test.dart` | Login success/failure |
| `widget_test.dart` | Theme smoke test |

## CI/CD

GitHub Actions workflow: `.github/workflows/ci.yml` — analyze + test on push/PR.

## FMCSA Compliance Notes

> **Disclaimer**: This codebase provides ELD-oriented architecture and data models aligned with 49 CFR Part 395. Full FMCSA certification requires registered ELD provider testing, third-party audit, and production hardware validation.

Implemented alignment:
- Automatic duty status recording with timestamps (UTC)
- Engine hours, speed, odometer, movement from ELD telemetry
- Location fields on HOS records
- Malfunction/diagnostic event annotation support
- 7/8-day log export structure (`fmcsa_format: ELD_OUTPUT_FILE`)
- Edit certification workflow documentation in Reports UI
- Secure token storage and encrypted Android shared preferences

**Production checklist**:
1. Register as ELD provider with FMCSA
2. Validate against Appendix A to Subpart B of Part 395
3. Complete road test with certified hardware (Geometris Whereqube, etc.)
4. Enable Sentry/Crashlytics (`AppLogger.reportCrash` placeholder)
5. Configure production API with audit logging
6. Legal review of privacy policy for location collection

## Edge Cases Handled

- Bluetooth unavailable → user messaging on Devices screen
- Permission denials → `PermissionFailure` mapped to UI snackbars
- Device disconnection → auto-reconnect (max 5 attempts)
- App restart → Hive-persisted HOS + secure token restore
- API unavailable → demo auth fallback for development
- Low battery → buffer cap at 5000 records to limit memory

## Project Structure Commands

```bash
# Code generation (when using freezed/retrofit generators)
dart run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze
```

## License

Proprietary — All rights reserved. Configure license before distribution.