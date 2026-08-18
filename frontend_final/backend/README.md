# Alpha Cues MVP

## Project Overview
Alpha Cues is a production-ready MVP blueprint for a **stock market alert and notification app** shipped as **native iOS and Android** apps (with optional Flutter Web). The product focuses on fast watchlist management, live price visibility, charts, strategy screening, manual portfolio tracking, and real-time alerts without introducing brokerage execution or KYC complexity in the first release.

The target architecture is a **modular monolith**:
- one Flutter client (**iOS + Android** primary; Web optional)
- one Flask backend
- one primary PostgreSQL database
- one Redis instance for caching, queues, and realtime fan-out

This repository is the **whole-product** source of truth (backend + mobile client plans):

- `ARCHITECTURE.md` — full-stack architecture
- `IMPLEMENTATION_PLAN.md` — backend + frontend tasks
- `README.md` — onboarding (this file)
- `plan.final_mobile.md` / `plan.final_mobile.html` — detailed mobile blueprint
- `docker-compose.yml` — local Postgres, Redis, Mailpit (for backend dev)
- `for-mvpweb/` — **copy-paste starter docs** for the [alphacues-mvpweb](https://github.com/AlphaCues-org/alphacues-mvpweb) Flutter repo (`README_web.md`, `ARCHITECTURE_web.md`, `IMPLEMENTATION_PLAN_web.md`)

The **mvpweb** repo should not duplicate full architecture; use `for-mvpweb/*` there and link back here.

## Tech Stack
### Frontend
- Flutter (iOS + Android primary; Web optional)
- Riverpod
- `go_router`
- `dio`
- Socket.IO client
- `google_fonts` with `Inter`
- charting library such as `fl_chart`
- `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `flutter_local_notifications`
- `connectivity_plus`, `package_info_plus`

### Backend
- Flask
- SQLAlchemy
- Alembic
- Celery
- Flask-SocketIO
- Flask-Limiter
- Marshmallow or Pydantic for validation/serialization

### Data and infrastructure
- PostgreSQL 16
- Redis 7
- Railway for backend, database, and worker deployment
- Vercel for Flutter Web deployment *(optional)*
- App Store Connect + Google Play Console for mobile releases
- Firebase for FCM (push) and optional Crashlytics

### External services
- Alpaca for real-time and market quote/history data
- Alpha Vantage for fundamentals and fallback metadata
- SendGrid for OTP email delivery
- Firebase Cloud Messaging for push notifications (Android + iOS)

## Setup Instructions (Frontend + Backend)
The recommended local workflow is **Docker-first** for infrastructure and **mock-first** for external providers.

### 1. Prerequisites
- Docker Desktop
- Python 3.12+
- Flutter stable with **iOS and Android** toolchains (Web optional)
- Xcode 15+ (macOS) for iOS builds
- Android Studio with SDK Platform **36**
- Apple Developer + Google Play Console accounts for store release
- Node.js is optional unless frontend tooling later requires it

### 2. Start local infrastructure
The repository includes a root `docker-compose.yml` with:
- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`
- optional Mailpit profile on `localhost:8025` for email capture

Run:

```bash
docker compose up -d
```

If you also want the email preview UI:

```bash
docker compose --profile mail up -d
```

### 3. Backend setup
Expected target layout:

```text
backend/
  app/
  migrations/
  requirements.txt
  .env.example
```

Install dependencies and run the API:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
flask --app app run --debug
```

Run worker, scheduler, and streamer in separate terminals:

```bash
cd backend
source .venv/bin/activate
python worker.py
```

```bash
cd backend
source .venv/bin/activate
python scheduler.py
```

```bash
cd backend
source .venv/bin/activate
python streamer.py
```

### 4. Frontend setup
Expected target layout:

```text
frontend/
  lib/
  test/
  web/
```

Install packages and run on Web or a device:

```bash
cd frontend
flutter pub get
flutter run -d chrome          # web (optional)
flutter devices
flutter run -d <device_id>     # iOS simulator or Android emulator
```

**Production mobile builds:**

```bash
cd frontend
flutter build appbundle --release   # Play Store
flutter build apk --release         # QA sideload
flutter build ipa --release         # TestFlight / App Store (macOS + signing)
```

Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase; keep secrets out of git.

## Environment Variables (.env example)
The MVP should support both **real provider mode** and **local mock mode**.

### Backend `.env.example`
```bash
APP_ENV=development
SECRET_KEY=replace-me
JWT_ISSUER=alphacues
JWT_AUDIENCE=alphacues-web
ACCESS_TOKEN_TTL_SECONDS=900
REFRESH_TOKEN_TTL_SECONDS=604800

DATABASE_URL=postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues
REDIS_URL=redis://localhost:6379/0

API_BASE_URL=http://localhost:5000
FRONTEND_BASE_URL=http://localhost:3000

MOCK_EXTERNAL_SERVICES=true
EMAIL_BACKEND=console
# EMAIL_BACKEND=smtp
# SMTP_HOST=localhost
# SMTP_PORT=1025

SENDGRID_API_KEY=
SENDGRID_FROM_EMAIL=alerts@alphacues.local

ALPACA_API_KEY=
ALPACA_SECRET_KEY=
ALPACA_DATA_FEED=iex
ALPACA_STREAM_URL=wss://stream.data.alpaca.markets/v2/iex

ALPHA_VANTAGE_API_KEY=

RATE_LIMIT_AUTH_PER_MINUTE=5
RATE_LIMIT_MARKET_SEARCH_PER_MINUTE=30

SENTRY_DSN=
LOG_LEVEL=INFO

FCM_PROJECT_ID=
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-service-account.json
```

### Frontend config (`.env` or `--dart-define`)

Use either a local `.env` file (loaded at build via your config bootstrap) **or** `--dart-define` at run/build time. Keep the **same variable names** in both places.

**`.env` example (local):**
```bash
API_BASE_URL=http://localhost:5000/api/v1
SOCKET_BASE_URL=http://localhost:5000
USE_MOCK_API=false
APP_NAME=Alpha Cues
PRIMARY_COLOR=#7061F3
DEEP_LINK_HOST=app.alphacues.com
```

**`--dart-define` example (staging build):**
```bash
flutter run --dart-define=API_BASE_URL=https://api-staging.alphacues.com/api/v1 \
  --dart-define=SOCKET_BASE_URL=https://api-staging.alphacues.com
```

## How to Run Locally
### Fastest local path without live API keys
1. Start Docker services with `docker compose up -d`
2. Set backend `MOCK_EXTERNAL_SERVICES=true`
3. Set `EMAIL_BACKEND=console` or use Mailpit SMTP
4. Run backend API, worker, scheduler, and streamer locally
5. Run Flutter on an emulator/device or Chrome (web optional)
6. Use the local auth flow with console OTP or Mailpit-captured email

### Local runtime expectations
- REST API base: `http://localhost:5000/api/v1`
- Socket.IO namespace: `/stream`
- Flutter app base: usually `http://localhost:3000` or the default Flutter web port
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- Mailpit UI: `http://localhost:8025`

### Recommended test commands
Backend:

```bash
cd backend
source .venv/bin/activate
pytest
```

Frontend:

```bash
cd frontend
flutter test
```

## Basic Usage Flow
1. User opens `/login` and enters an email address.
2. Backend sends a 6-digit OTP through SendGrid, console output, or Mailpit depending on environment.
3. User enters the code on `/verify-otp`.
4. Frontend stores the access and refresh tokens and redirects to `/dashboard`.
5. User creates a watchlist and adds symbols.
6. Dashboard and watchlist pages load current quote snapshots through REST.
7. Socket.IO connects to `/stream` and starts sending live quote and notification updates.
8. User creates `ABOVE`, `BELOW`, or `PERCENT_CHANGE` alerts.
9. Backend evaluates alerts from live market updates and writes notifications.
10. User receives in-app notifications immediately and email notifications when enabled.
11. On mobile, the app registers an FCM token; push delivers alerts when backgrounded or killed.
12. Tapping a push opens the target screen via deep link (e.g. `/symbols/AAPL`).

## Mock and Stub Strategy
Local development should not depend on live Alpaca, Alpha Vantage, or SendGrid keys.

### Backend adapter strategy
- `EmailSender`
  - production: SendGrid
  - local: console sender or Mailpit SMTP
- `MarketDataSource`
  - production: Alpaca + Alpha Vantage
  - local/CI: fixture-backed fake provider

### Frontend strategy
- preferred mode: connect the real local Flask API with mocked external services behind it
- optional mode: set `USE_MOCK_API=true` for pure UI work before backend endpoints exist

## Contracts and Compatibility Rules
- canonical base path: `/api/v1`
- auth header: `Authorization: Bearer <JWT>`
- shared response envelope:

```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": {
    "requestId": "uuid",
    "apiVersion": "1"
  }
}
```

- stable query parameter names to preserve:
  - `symbol`
  - `symbols`
  - `q`
  - `timeframe`
- stable enum values to preserve:
  - `BUY`
  - `SELL`
  - `ABOVE`
  - `BELOW`
  - `PERCENT_CHANGE`
- stable database table names to preserve where possible:
  - `users`
  - `otp_tokens`
  - `portfolio_event`
  - `positions`
  - `portfolio_snapshot`
  - `stock_tick`
  - `watchlists`
  - `watchlist_items`
  - `alerts`
  - `notifications`
  - `feature_flags`

## Edge Cases and Degraded Behavior
### OTP
- expires after 5 minutes
- 5 wrong attempts lock the challenge context for 15 minutes
- resend is rate-limited
- wrong OTP responses stay generic enough to reduce account enumeration

### Session
- access token expiry should trigger a single refresh attempt
- refresh failure logs the user out and redirects to `/login`

### WebSocket
- disconnect mid-session shows a reconnect banner
- reconnect triggers re-subscribe plus REST refresh
- auth failure on reconnect should stop infinite retry loops

### Redis
- if cache is unavailable, read paths degrade to direct database or provider fetches where safe
- auth rate-limit paths should fail closed
- websocket fan-out may degrade, but REST remains the correctness layer

### Empty-state UX
- no watchlists: show create-watchlist CTA
- no holdings: show add-holdings CTA
- no alerts: show create-alert CTA
- no screener matches: show "No matches" state, not a blank table

## Recommended Reading Order
1. `ARCHITECTURE.md`
2. `IMPLEMENTATION_PLAN.md`
3. `README.md`
4. `plan.final_mobile.md` or `plan.final_mobile.html` (mobile-specific blueprint)

## Current Repository Status
This repository currently documents the MVP blueprint and implementation plan. The next engineering step is to scaffold `backend/` and `frontend/` following `IMPLEMENTATION_PLAN.md`.