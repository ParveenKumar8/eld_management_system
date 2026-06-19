# ELD Management API

NestJS REST API for the ELD Management mobile app.

## Quick start

```bash
# From repo root — start PostgreSQL
docker compose up -d postgres

# Backend
cd backend
cp .env.example .env
npm install
npx prisma db push
npm run prisma:seed
npm run start:dev
```

- API base: `http://localhost:3000/v1`
- Swagger: `http://localhost:3000/docs`

## Demo credentials

- Email: `driver@demo.eld`
- Password: `password123`

## Mobile dev

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1 --dart-define=USE_DEMO_AUTH=false
```

Use `http://127.0.0.1:3000/v1` for iOS simulator.

## HOS endpoints (Phase 3)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/hos/records?days=8` | List driver HOS log records |
| POST | `/hos/records/sync` | Batch upsert records from mobile outbox |
| GET | `/hos/summary` | FMCSA HOS summary for authenticated driver |

Mobile writes duty changes to Hive first, queues them in `hos_outbox`, and syncs via Workmanager (every 15 min) or immediately when online.

## ELD telemetry endpoints (Phase 4)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/eld/telemetry/batch` | Batch upload buffered BLE telemetry |
| GET | `/eld/telemetry?limit=100&since=...` | Recent telemetry for authenticated driver |

Each parsed BLE frame is persisted to `eld_buffer`, queued in `eld_outbox`, and uploaded in batches of up to 200 events when online.

## Location & profile endpoints (Phase 5)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/location/trail/batch` | Batch upload GPS trail points |
| GET | `/location/trail?days=8&limit=500` | Recent trail for authenticated driver |
| GET | `/drivers/me` | Driver profile (pull sync) |
| PATCH | `/drivers/me` | Update display name / CDL number |

GPS fixes persisted during tracking are queued in `location_outbox`. Profile edits are cached locally and pushed via `profile_pending` when online.

## Compliance & fleet push (Phase 6)

| Method | Path | Description |
|--------|------|-------------|
| PATCH | `/hos/records/:id` | Edit a log entry (requires `annotation`, sets `is_edited`) |
| POST | `/hos/certify` | Certify uncertified records in rolling window (`days`, default 8) |
| POST | `/notifications/push` | Fleet manager / admin push to driver device tokens |

Mobile edits logs locally first, syncs via outbox when online, and drivers certify from **Compliance → Edit Requests**. Fleet push requires `FIREBASE_PROJECT_ID` (see `.env.example`).

### Fleet demo credentials

- Email: `fleet@demo.eld`
- Password: `fleet123`