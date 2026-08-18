# Alpha Cues — Mobile App (alphacues-mvpweb)

Flutter **iOS + Android** client for Alpha Cues. Talks to the Flask API documented in the **[alphacues-mvpapi](https://github.com/AlphaCues-org/alphacues-mvpapi)** repo.

## Canonical docs (do not duplicate here)

| Document | Location |
|---|---|
| Full system architecture | [alphacues-mvpapi/ARCHITECTURE.md](https://github.com/AlphaCues-org/alphacues-mvpapi/blob/main/ARCHITECTURE.md) |
| Full implementation plan | [alphacues-mvpapi/IMPLEMENTATION_PLAN.md](https://github.com/AlphaCues-org/alphacues-mvpapi/blob/main/IMPLEMENTATION_PLAN.md) |
| Mobile blueprint (detailed) | [alphacues-mvpapi/plan.final_mobile.md](https://github.com/AlphaCues-org/alphacues-mvpapi/blob/main/plan.final_mobile.md) |
| Whole-product onboarding | [alphacues-mvpapi/README.md](https://github.com/AlphaCues-org/alphacues-mvpapi/blob/main/README.md) |

This repo’s `ARCHITECTURE.md` and `IMPLEMENTATION_PLAN.md` are **short, frontend-only** views (paste from this folder). Change API contracts in **alphacues-mvpapi** first, then update Flutter here.

## Tech stack (this repo)

- Flutter (iOS + Android; Web optional)
- Riverpod, `go_router`, `dio`, Socket.IO client
- `google_fonts` (Inter), `fl_chart` (or similar)
- `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- `flutter_secure_storage`, `connectivity_plus`, `package_info_plus`
- `cached_network_image` (symbol logos / avatars)
- Release observability: Firebase Crashlytics or `sentry_flutter`

## Prerequisites

- Flutter stable (iOS + Android enabled)
- Xcode 15+ (macOS) for iOS
- Android Studio with **SDK Platform 36**
- Firebase project (`google-services.json`, `GoogleService-Info.plist` — gitignored)
- Running API from **alphacues-mvpapi** (`docker compose up -d` + Flask) — see alphacues-mvpapi README

## Setup

```bash
flutter pub get
```

Firebase config (do not commit to public repos):

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Add to `.gitignore` when Firebase is wired.

## Configuration

Use **either** a local config file **or** `--dart-define` with the **same variable names** (aligned with alphacues-mvpapi README).

| Variable | Example | Purpose |
|---|---|---|
| `API_BASE_URL` | `http://localhost:5000/api/v1` | REST |
| `SOCKET_BASE_URL` | `http://localhost:5000` | Socket.IO `/stream` |
| `DEEP_LINK_HOST` | `app.alphacues.com` | Universal / App Links |
| `USE_MOCK_API` | `false` | Pure UI mock mode (no Flask) |

**`.env`-style (local file, loaded by your bootstrap):**
```bash
API_BASE_URL=http://localhost:5000/api/v1
SOCKET_BASE_URL=http://localhost:5000
USE_MOCK_API=false
DEEP_LINK_HOST=app.alphacues.com
```

**`--dart-define` (staging example):**
```bash
flutter run --dart-define=API_BASE_URL=https://api-staging.alphacues.com/api/v1 \
  --dart-define=SOCKET_BASE_URL=https://api-staging.alphacues.com
```

Defaults can use localhost until staging exists.

**Build flavors (dev / staging / prod):** see IMPLEMENTATION_PLAN Task 28.

## Run locally

```bash
flutter devices
flutter run -d <device_id>
flutter run -d chrome                # optional web
flutter run --release -d <device_id>
```

Backend must be up in **alphacues-mvpapi**. OTP: console (`EMAIL_BACKEND=console`) or Mailpit UI at `http://localhost:8025`.

## Release builds

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.alphacues.com/api/v1
flutter build apk --release
flutter build ipa --release
```

## Tests & CI

```bash
flutter analyze
flutter test
```

- Contract fixtures: copy/sync from `alphacues-mvpapi/backend/tests/fixtures/contracts/` → `test/contracts/`
- CI (Task 7): analyze + test on every PR; release workflow for AAB/IPA per flavor

## Implementation tasks (this repo)

See `IMPLEMENTATION_PLAN.md`: Tasks 1, 5–7, 9–13, 15, 17, 19, 22–23, 24–29 (frontend). Backend Tasks 2–4, 8, 10, 14, 16, 18, 20–21 live in **alphacues-mvpapi**.

## Basic usage flow

1. User opens `/login` and enters email.
2. Backend sends OTP (SendGrid, console, or Mailpit).
3. User verifies on `/verify-otp`.
4. App stores tokens in **secure storage** and opens `/dashboard`.
5. User creates a watchlist and adds symbols.
6. Dashboard/watchlist load quotes via REST.
7. Socket.IO connects to `/stream` for live quotes and notifications.
8. User creates `ABOVE`, `BELOW`, or `PERCENT_CHANGE` alerts.
9. Backend evaluates alerts and writes notifications.
10. User sees in-app updates; email if enabled.
11. Mobile registers FCM token; push when backgrounded/killed.
12. Tap push → deep link (e.g. `/symbols/AAPL`).

## Mock and stub strategy

- **Preferred:** real local Flask API with `MOCK_EXTERNAL_SERVICES=true` in alphacues-mvpapi (fake market/email behind API).
- **UI-only:** `USE_MOCK_API=true` in this app before endpoints exist.
- **OTP locally:** alphacues-mvpapi `EMAIL_BACKEND=console` prints code to terminal, or Mailpit captures email.

## Edge cases (client behavior)

### OTP / session
- OTP expires in 5 minutes; 5 wrong attempts → 15-minute lock
- Access token expiry → single refresh attempt; refresh failure → logout → `/login`

### WebSocket
- Disconnect → “Live prices reconnecting…” banner; backoff; re-subscribe + REST refresh
- Auth failure on reconnect → stop infinite retries

### Offline / connectivity
- `connectivity_plus` offline banner; show cached data + stale timestamp (Task 29)
- Disable mutating actions when offline if API unreachable

### Empty states
- No watchlists → create CTA; no holdings → add CTA; no alerts → create CTA; screener → “No matches”

## Repo layout (target)

```text
lib/
  app/          # router, theme
  core/         # api, auth, realtime, push, connectivity, storage
  features/
android/
ios/
test/
test/contracts/       # synced from alphacues-mvpapi
integration_test/
```
