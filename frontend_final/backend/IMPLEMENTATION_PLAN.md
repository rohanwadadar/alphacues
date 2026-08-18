# Alpha Cues MVP Implementation Plan

> **Mobile:** Native **iOS + Android** is the primary client. See **Phase 4** for mobile shell, push, deep links, and store release. Full detail: `plan.final_mobile.md`.

This plan is intentionally split into **backend-first** and **frontend-first** tasks so the project can be developed and committed in small, reviewable units without entangling UI and API work.

## Phase 1: MVP Foundation
Goal: establish the repo skeleton, local development environment, contract-safe auth flow, shared infrastructure, and test harness.

### Step-by-step tasks
#### 1. Local infrastructure and repo skeleton
**Backend**
- create `backend/` application root
- add `docker-compose.yml` for PostgreSQL 16 and Redis 7
- add optional Mailpit profile for local email capture
- add `backend/.env.example`
- create `backend/requirements.txt`, `backend/wsgi.py`, `backend/worker.py`, `backend/scheduler.py`, `backend/streamer.py`

**Frontend**
- create `frontend/` Flutter app (iOS + Android + optional Web)
- add core dependencies: `flutter_riverpod`, `go_router`, `dio`, `socket_io_client`, `google_fonts`
- add mobile dependencies: `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `flutter_local_notifications`, `connectivity_plus`, `package_info_plus`
- configure `android/` (`compileSdk`/`targetSdk` 36) and `ios/` (deployment target, push + associated domains)
- add environment/config bootstrap

**File/module-level breakdown**
- `docker-compose.yml`
- `backend/app/__init__.py`
- `backend/app/extensions.py`
- `backend/app/config/base.py`
- `backend/app/config/development.py`
- `backend/app/config/production.py`
- `backend/app/config/testing.py`
- `backend/wsgi.py`
- `backend/worker.py`
- `backend/scheduler.py`
- `backend/streamer.py`
- `frontend/lib/main.dart`
- `frontend/lib/app/app.dart`

**Dependencies between tasks**
- none; this is the foundation for all other work

**Testing strategy**
- backend smoke test: app boots with `docker compose up`
- frontend smoke test: app renders shell route on Android emulator / iOS simulator (and Chrome if Web enabled)
- CI smoke job: install dependencies and run the smallest boot test for both apps
- CI: `flutter analyze`, `flutter test`, `flutter build apk --debug` (Linux); `flutter build ios --no-codesign` (macOS)

**Risks or blockers**
- Apple Silicon image mismatch: use official multi-arch Docker images
- Railway runtime mismatch: align local Python and PostgreSQL versions with production

#### 2. Shared backend infrastructure
**Backend**
- implement `ResponseFactory` / `json_response()` for the canonical API envelope
- add global error handler with `requestId`
- add SQLAlchemy setup, Alembic migration wiring, and Redis client
- add rate limiter config
- add validation helpers for email, symbol, pagination, and sorting
- add feature-flag access service reading from `feature_flags`
- add auth decorators for JWT verification
- add logging and request correlation middleware

**File/module-level breakdown**
- `backend/app/shared/response.py`
- `backend/app/shared/error_handler.py`
- `backend/app/shared/db.py`
- `backend/app/shared/cache.py`
- `backend/app/shared/limiter.py`
- `backend/app/shared/validators.py`
- `backend/app/shared/feature_flags.py`
- `backend/app/shared/auth.py`
- `backend/app/shared/logging.py`

**Dependencies between tasks**
- depends on Task 1 backend skeleton

**Testing strategy**
- unit tests for response envelope helper and validators
- integration tests for 404, 422, and 500 error shapes
- integration test that `requestId` appears in every response `meta`

**Risks or blockers**
- response-envelope drift if routes bypass the helper
- Redis-dependent rate limiting must fail closed for `/auth/*`

#### 3. Initial database schema and migrations
**Backend**
- create migrations for:
  - `users`
  - `otp_tokens`
  - `user_sessions`
  - `feature_flags`
- seed required feature flags:
  - `use_microservice_auth`
  - `use_microservice_portfolio`
  - `use_microservice_market`
  - `enable_live_trading`
  - `enable_simulator`
  - `enable_screener`

**File/module-level breakdown**
- `backend/migrations/versions/*`
- `backend/app/modules/user/models.py`
- `backend/app/shared/feature_flags.py`
- `backend/scripts/seed_feature_flags.py`

**Dependencies between tasks**
- depends on Task 2 shared DB wiring

**Testing strategy**
- migration test on a clean database
- seed test verifying exact flag names
- downgrade smoke test in local/dev only

**Risks or blockers**
- inconsistent naming if migrations diverge from architecture contract
- destructive migration habits early in the project

#### 4. Auth module backend
**Backend**
- implement email normalization
- implement OTP challenge creation, hashing, expiry, resend invalidation, lockouts, and verification
- implement JWT issuance and refresh rotation
- implement session persistence in `user_sessions`
- add auth routes:
  - `POST /api/v1/auth/send-otp`
  - `POST /api/v1/auth/verify-otp`
  - `POST /api/v1/auth/refresh`
  - `POST /api/v1/auth/logout`
  - `GET /api/v1/auth/verify`
  - `GET /api/v1/auth/me`
  - `PUT /api/v1/auth/me`
- implement `EmailSender` interface with:
  - `SendGridEmailSender`
  - `ConsoleEmailSender`
  - optional SMTP/Mailpit sender

**File/module-level breakdown**
- `backend/app/modules/user/routes.py`
- `backend/app/modules/user/service.py`
- `backend/app/modules/user/models.py`
- `backend/app/modules/user/schemas.py`
- `backend/app/adapters/protocols.py`
- `backend/app/adapters/email_sender.py`
- `backend/app/adapters/fake_email_sender.py`
- `backend/app/modules/user/tests/test_auth_service.py`
- `backend/app/modules/user/tests/test_auth_routes.py`

**Dependencies between tasks**
- depends on Tasks 2 and 3

**Testing strategy**
- unit tests:
  - OTP generation and hash comparison
  - OTP expiry boundary
  - resend invalidates previous challenge
  - wrong OTP 5 times triggers lock
  - refresh token rotation
- integration tests:
  - send OTP success
  - verify OTP success
  - refresh access token
  - logout clears session
- contract tests:
  - fixture for `send-otp` success
  - fixture for `verify-otp` success
  - fixtures for `OTP_INVALID`, `OTP_EXPIRED`, `OTP_LOCKED`

**Risks or blockers**
- bad OTP retry policy can enable abuse or accidental lockout
- token refresh bugs can cause hard-to-debug frontend loops

#### 5. Frontend app shell and routing
**Frontend**
- implement app theme, typography, color system, spacing
- configure `go_router`
- add route guards and authenticated shell
- add reusable empty/error/loading widgets
- add environment config and API base URL handling

**File/module-level breakdown**
- `frontend/lib/app/router/app_router.dart`
- `frontend/lib/app/router/route_guards.dart`
- `frontend/lib/app/theme/app_theme.dart`
- `frontend/lib/app/theme/app_colors.dart`
- `frontend/lib/app/theme/app_typography.dart`
- `frontend/lib/core/widgets/loading_skeleton.dart`
- `frontend/lib/core/widgets/empty_state.dart`
- `frontend/lib/core/widgets/error_state.dart`
- `frontend/lib/core/config/app_config.dart`

**Dependencies between tasks**
- depends on Task 1 frontend skeleton

**Testing strategy**
- widget test: unauthenticated `/dashboard` redirects to `/login`
- widget test: authenticated root redirects to `/dashboard`
- widget test: `enable_screener=false` hides screener route entry

**Risks or blockers**
- routing complexity grows quickly if route guards also own data loading
- inconsistent state widgets make the UI feel unfinished

#### 6. Frontend auth flow
**Frontend**
- implement auth repository and session provider
- implement email entry screen
- implement OTP verification screen with countdown, resend, and error states
- implement token refresh lock in the `dio` interceptor
- implement logout invalidation across feature providers
- on mobile, after successful `verifyOtp`, register FCM device token with backend (`POST /api/v1/devices/register`) when push is enabled (full wiring in Task 25; stub call acceptable until backend endpoint exists)

**File/module-level breakdown**
- `frontend/lib/core/network/api_client.dart`
- `frontend/lib/core/auth/auth_session.dart`
- `frontend/lib/core/auth/auth_token_store.dart`
- `frontend/lib/features/auth/data/auth_repository.dart`
- `frontend/lib/features/auth/presentation/login_screen.dart`
- `frontend/lib/features/auth/presentation/verify_otp_screen.dart`
- `frontend/test/features/auth/*`

**Dependencies between tasks**
- depends on Task 4 backend contract and Task 5 routing shell

**Testing strategy**
- provider tests:
  - send OTP
  - verify OTP
  - single-flight refresh lock
  - logout invalidates user-scoped providers
- widget tests:
  - expired OTP error copy
  - locked account state
  - resend countdown state

**Risks or blockers**
- storing refresh tokens insecurely in browser storage
- infinite refresh loops if 401 handling is not carefully guarded

#### 7. CI and local developer workflow
**Backend**
- add `pytest`, lint, and migration checks
- add fixture-driven contract tests

**Frontend**
- add `flutter test`, formatting, and analyzer checks

**Mobile CI/CD**
- add `.github/workflows/mobile-release.yml` for `flutter build appbundle --release` and `flutter build ipa --release`
- document signing secrets (Android keystore, Play service account, iOS certs, App Store Connect API key)
- **build flavor matrix** (via `--dart-define` or `flutter_flavorizr`):
  - `dev` → `API_BASE_URL=http://localhost:5000/api/v1`
  - `staging` → staging API host
  - `prod` → production API host
- CI runs analyze/test on every PR; release workflow builds **dev** (debug APK), **staging**, and **prod** (AAB + IPA) with matching defines

**File/module-level breakdown**
- `.github/workflows/ci.yml`
- `.github/workflows/mobile-release.yml`
- `backend/tests/fixtures/contracts/*`
- `frontend/test/contracts/*`
- `Makefile` or root scripts for local commands

**Dependencies between tasks**
- depends on Tasks 1 through 6

**Testing strategy**
- CI must run backend unit/integration tests and frontend tests on every PR
- CI must boot Postgres and Redis using service containers or compose

**Risks or blockers**
- if contract fixtures are added late, frontend and backend drift becomes expensive to unwind

### Phase 1 summary dependencies
1 -> 2 -> 3 -> 4 -> 6  
1 -> 5 -> 6  
1..6 -> 7

### Phase 1 main risks
- auth contract changes after frontend wiring begins
- Redis outages affecting auth rate limits if failure policy is unclear
- local setup friction if Docker is not the default path

## Phase 2: Core Features
Goal: build the core user value loop: dashboard, watchlists, charts, alerts, notifications, portfolio, and realtime updates.

### Step-by-step tasks
#### 8. Market data module backend
**Backend**
- implement `MarketDataSource` interface
- implement production adapters for Alpaca and Alpha Vantage
- implement fake adapters for local dev and CI
- add quote, bars, snapshot, search, movers, and fundamentals endpoints
- add caching rules and request coalescing
- store or materialize bar data into `stock_tick` and rollups

**File/module-level breakdown**
- `backend/app/modules/market/routes.py`
- `backend/app/modules/market/service.py`
- `backend/app/modules/market/models.py`
- `backend/app/modules/market/schemas.py`
- `backend/app/adapters/market_data.py`
- `backend/app/adapters/fake_market_data.py`
- `backend/app/modules/market/tests/*`

**Dependencies between tasks**
- depends on Phase 1 shared infrastructure and auth

**Testing strategy**
- unit tests for cache hit/miss behavior
- integration tests for quote, bars, snapshot, and search
- contract fixtures for bar payload shape and `timeframe`/`range` rules

**Risks or blockers**
- Alpha Vantage daily quota is low; fundamentals must be heavily cached
- old `timeframe=1D` assumptions can leak back in unless contract tests are strict

#### 9. Realtime infrastructure
**Backend**
- implement Socket.IO namespace `/stream`
- authenticate websocket handshakes using access JWT
- implement subscription management and backpressure protection
- connect Redis pub-sub for horizontal fan-out

**Frontend**
- implement socket client
- implement visible-symbol subscription manager
- add connection-state banner and reconnect behavior

**File/module-level breakdown**
- `backend/app/shared/websocket.py`
- `backend/app/extensions.py`
- `backend/streamer.py`
- `frontend/lib/core/realtime/socket_client.dart`
- `frontend/lib/core/realtime/socket_events.dart`
- `frontend/lib/core/realtime/quote_subscription_manager.dart`

**Dependencies between tasks**
- depends on Task 8 market data backend

**Testing strategy**
- backend integration test: websocket connection rejects expired JWT
- frontend unit test: reconnect backoff and re-subscribe logic
- integration test: reconnect triggers REST refresh before live badge clears

**Risks or blockers**
- Socket.IO scaling requires sticky behavior awareness in production
- too many client subscriptions can waste upstream quota

#### 10. Watchlist module backend
**Backend**
- implement watchlist CRUD
- implement add/remove symbol logic
- enforce duplicate prevention
- add detail endpoint that joins live/stale quotes

**File/module-level breakdown**
- `backend/app/modules/watchlist/routes.py`
- `backend/app/modules/watchlist/service.py`
- `backend/app/modules/watchlist/models.py`
- `backend/app/modules/watchlist/schemas.py`
- `backend/app/modules/watchlist/tests/*`

**Dependencies between tasks**
- depends on Task 8

**Testing strategy**
- unit tests for duplicate symbol protection
- integration tests for CRUD and symbol add/remove
- contract fixture for list and detail payloads

**Risks or blockers**
- watchlist detail can become slow if quote enrichment is not batched

#### 11. Watchlist module frontend
**Frontend**
- implement watchlist list screen
- implement create, rename, delete, add symbol, remove symbol
- show live/stale prices and empty states
- deep-link watchlist detail route

**File/module-level breakdown**
- `frontend/lib/features/watchlist/data/watchlist_repository.dart`
- `frontend/lib/features/watchlist/presentation/watchlists_screen.dart`
- `frontend/lib/features/watchlist/presentation/watchlist_detail_screen.dart`
- `frontend/lib/features/watchlist/presentation/watchlist_form_dialog.dart`
- `frontend/test/features/watchlist/*`

**Dependencies between tasks**
- depends on Task 10 backend and Task 9 realtime

**Testing strategy**
- widget test: empty watchlist state
- widget test: duplicate symbol inline error
- provider test: add/remove symbol invalidates detail provider only

**Risks or blockers**
- route-level state can get messy if dialogs own API mutation logic directly

#### 12. Dashboard and symbol detail frontend
**Frontend**
- implement dashboard aggregate screen
- add top movers, watchlist summary, portfolio summary, and notification bell
- implement symbol detail screen with quote, chart, and fundamentals summary

**File/module-level breakdown**
- `frontend/lib/features/dashboard/data/dashboard_repository.dart`
- `frontend/lib/features/dashboard/presentation/dashboard_screen.dart`
- `frontend/lib/features/market/presentation/symbol_detail_screen.dart`
- `frontend/lib/features/dashboard/presentation/widgets/*`

**Dependencies between tasks**
- depends on Tasks 8, 9, and 11

**Testing strategy**
- widget smoke tests for dashboard loading/data/error states
- widget test for symbol detail invalid symbol state

**Risks or blockers**
- dashboard payload must stay coarse-grained or the frontend will overfetch

#### 13. Charts frontend
**Frontend**
- add candlestick chart widget
- map `timeframe` and `range` correctly
- add hover/tap tooltip, timeframe selector, and stale badge
- add zero-data and partial-data handling

**File/module-level breakdown**
- `frontend/lib/features/market/presentation/widgets/stock_chart.dart`
- `frontend/lib/features/market/presentation/widgets/timeframe_selector.dart`
- `frontend/lib/features/market/data/market_repository.dart`
- `frontend/test/features/market/*`

**Dependencies between tasks**
- depends on Task 8 bars endpoint and Task 12 symbol detail shell

**Testing strategy**
- widget test for chart rendering with fixture bars
- mapping test for `range -> timeframe request` behavior
- widget test for empty history state

**Risks or blockers**
- chart libraries can re-render too often if providers emit full lists on every tick

#### 14. Alerts module backend
**Backend**
- implement alert CRUD
- implement evaluation logic for `ABOVE`, `BELOW`, and `PERCENT_CHANGE`
- add cooldown and idempotent trigger handling
- write `alert_trigger_events`, `notifications`, and `outbox_events`
- add notification feed endpoints

**File/module-level breakdown**
- `backend/app/modules/alerts/routes.py`
- `backend/app/modules/alerts/service.py`
- `backend/app/modules/alerts/models.py`
- `backend/app/modules/alerts/schemas.py`
- `backend/app/modules/notifications/routes.py`
- `backend/app/modules/notifications/service.py`
- `backend/app/modules/notifications/models.py`
- `backend/app/modules/alerts/tests/*`
- `backend/app/modules/notifications/tests/*`

**Dependencies between tasks**
- depends on Tasks 8 and 9

**Testing strategy**
- unit tests:
  - threshold crossing
  - cooldown behavior
  - duplicate trigger prevention
- integration tests:
  - create/update/delete alert
  - notification feed pagination
- contract fixtures:
  - alert list
  - notification list
  - alert triggered event

**Risks or blockers**
- duplicate notifications if evaluator and worker idempotency are not explicit

#### 15. Alerts and notifications frontend
**Frontend**
- implement alerts list and create/edit form
- implement notifications dropdown/panel
- add real-time notification insertion and read/unread transitions
- show clear empty/offline/error states

**File/module-level breakdown**
- `frontend/lib/features/alerts/data/alerts_repository.dart`
- `frontend/lib/features/alerts/presentation/alerts_screen.dart`
- `frontend/lib/features/alerts/presentation/alert_form_dialog.dart`
- `frontend/lib/features/notifications/data/notifications_repository.dart`
- `frontend/lib/features/notifications/presentation/notifications_panel.dart`
- `frontend/test/features/alerts/*`
- `frontend/test/features/notifications/*`

**Dependencies between tasks**
- depends on Task 14 backend and Task 9 realtime

**Testing strategy**
- widget test for create-alert validation
- provider test for websocket notification insert
- widget test for "You're all caught up" empty state

**Risks or blockers**
- notifications panel can become stateful and flaky if it mixes fetch and socket merge logic in the widget layer

#### 16. Portfolio module backend
**Backend**
- implement manual portfolio event ledger and positions summary
- compute total value, total profit, total return, and day change
- expose transactions and history endpoints

**File/module-level breakdown**
- `backend/app/modules/portfolio/routes.py`
- `backend/app/modules/portfolio/service.py`
- `backend/app/modules/portfolio/models.py`
- `backend/app/modules/portfolio/schemas.py`
- `backend/app/modules/portfolio/tests/*`

**Dependencies between tasks**
- depends on Task 8 market quotes and Phase 1 auth

**Testing strategy**
- unit tests for cost-basis math
- unit tests for realized and unrealized P/L
- integration tests for ledger entry create/list
- contract fixture for portfolio summary

**Risks or blockers**
- unclear cost-basis semantics can break user trust quickly; keep the math simple and explicit

#### 17. Portfolio module frontend
**Frontend**
- implement holdings summary and transaction list
- implement add/edit/delete manual BUY/SELL entries
- show empty portfolio CTA and stale-price labels

**File/module-level breakdown**
- `frontend/lib/features/portfolio/data/portfolio_repository.dart`
- `frontend/lib/features/portfolio/presentation/portfolio_screen.dart`
- `frontend/lib/features/portfolio/presentation/portfolio_event_form_dialog.dart`
- `frontend/test/features/portfolio/*`

**Dependencies between tasks**
- depends on Task 16 backend and Task 9 realtime

**Testing strategy**
- widget test for empty holdings state
- form validation test for quantity and price
- provider test for summary refresh after event mutation

**Risks or blockers**
- if event editing rules are vague, users can create confusing history states

### Phase 2 summary dependencies
8 -> 9  
8 -> 10 -> 11  
8 + 9 + 11 -> 12  
8 + 12 -> 13  
8 + 9 -> 14 -> 15  
8 -> 16 -> 17

### Phase 2 main risks
- external market-provider quotas
- websocket churn and stale-state handling
- cross-module contract drift between market, alerts, and dashboard

## Phase 3: Enhancements
Goal: add the screener, tighten feature flags and migration safety, and harden reliability, performance, accessibility, and observability for production.

### Step-by-step tasks
#### 18. Screener backend
**Backend**
- implement strategy storage in `screener_strategies`
- define supported filters and sorting
- add deterministic screening over a cached market/fundamental dataset
- preserve filter field names and enum values in fixtures

**File/module-level breakdown**
- `backend/app/modules/screener/routes.py`
- `backend/app/modules/screener/service.py`
- `backend/app/modules/screener/models.py`
- `backend/app/modules/screener/schemas.py`
- `backend/app/modules/screener/tests/*`

**Dependencies between tasks**
- depends on Task 8 market data and Phase 1 shared infrastructure

**Testing strategy**
- unit tests for filter validation
- deterministic scan test over fixture dataset
- contract fixture for screener results and saved strategies

**Risks or blockers**
- screener scope can expand too far; keep MVP filters intentionally narrow

#### 19. Screener frontend
**Frontend**
- implement screener filter form and results table
- add saved strategy create/delete flow
- show zero-result state and flag-disabled state

**File/module-level breakdown**
- `frontend/lib/features/screener/data/screener_repository.dart`
- `frontend/lib/features/screener/presentation/screener_screen.dart`
- `frontend/lib/features/screener/presentation/widgets/*`
- `frontend/test/features/screener/*`

**Dependencies between tasks**
- depends on Task 18 backend and `enable_screener`

**Testing strategy**
- widget test for empty results state
- widget test for feature-disabled screen
- provider test for save/delete strategy

**Risks or blockers**
- dynamic forms can become too complex if every future indicator is added now

#### 20. Feature-flag admin and compatibility controls
**Backend**
- add admin-only flag read/update endpoints
- add caching or request memoization that still respects fast flag flips
- add compatibility aliases for legacy routes if migration requires them

**File/module-level breakdown**
- `backend/app/modules/admin/routes.py`
- `backend/app/modules/admin/service.py`
- `backend/app/shared/feature_flags.py`
- `backend/tests/integration/test_feature_flags.py`

**Dependencies between tasks**
- depends on Phase 1 feature flag schema

**Testing strategy**
- integration test: disabled screener returns `403 FEATURE_DISABLED`
- integration test: enabling a flag changes runtime behavior without deploy
- compatibility tests for legacy alias behavior if those aliases are included

**Risks or blockers**
- overly aggressive caching can violate the "flag flip without deploy" promise

#### 21. Contract versioning and migration safety
**Backend**
- freeze JSON fixtures per module
- document deprecation policy
- add migration checklist for additive changes, forward-fix rollbacks, and `/api/v2`
- add migration support for any new alert or market fields

**File/module-level breakdown**
- `backend/tests/fixtures/contracts/*`
- `backend/docs/api_compatibility.md`
- `backend/scripts/contract_check.py`
- `CHANGELOG.md`

**Dependencies between tasks**
- depends on all public endpoints from Phases 1 and 2

**Testing strategy**
- CI contract test comparing actual responses to fixture structure
- migration test for additive alert-model changes

**Risks or blockers**
- undocumented additive fields can still break the frontend if nullability changes unexpectedly

#### 22. Performance and reliability hardening
**Backend**
- add or confirm all indexes
- measure slow endpoints
- add request batching and quote fan-out optimization
- implement outbox retry policies and dead-letter visibility
- add queue-depth, lag, and stale-cache monitoring

**Frontend**
- reduce unnecessary rebuilds
- debounce search
- virtualize or paginate larger lists where needed
- use `cached_network_image` for symbol logos and `avatarUrl` thumbnails

**File/module-level breakdown**
- `backend/app/shared/cache.py`
- `backend/app/shared/logging.py`
- `backend/tests/performance/*`
- `frontend/lib/core/realtime/quote_subscription_manager.dart`
- `frontend/test/performance/*`

**Dependencies between tasks**
- depends on Phases 1 and 2 feature completeness

**Testing strategy**
- backend load test for dashboard and watchlist
- quote-subscription stress test
- reconnect chaos test

**Risks or blockers**
- over-optimizing before measuring can add complexity without value

#### 23. Security, accessibility, and observability hardening
**Backend**
- tighten CORS, security headers, and secrets handling
- audit auth logs and abuse signals
- add Sentry integration

**Frontend**
- accessibility pass: semantics on icon-only controls, screen-reader labels on price change indicators, focus order on forms
- **TalkBack / VoiceOver:** reading order matches visual order on dashboard, watchlist rows, and alert list; announce alert trigger toasts
- contrast minimum **4.5:1** on body text; test at system font scale **1.3×**
- keyboard navigation and toasts (web); large touch targets already required on mobile (Task 24)
- add production-grade degraded-state copy
- release builds: `sentry_flutter` or **Firebase Crashlytics** + optional Performance monitoring

**File/module-level breakdown**
- `backend/app/shared/security.py`
- `backend/app/shared/logging.py`
- `frontend/lib/core/widgets/*`
- `.github/workflows/release.yml`

**Dependencies between tasks**
- depends on all user-facing features being present

**Testing strategy**
- smoke security tests for auth endpoints
- accessibility widget audits for major screens
- staging smoke checklist for login, dashboard, alerts, and reconnect

**Risks or blockers**
- if observability is postponed too long, production incidents will be harder to diagnose

### Phase 3 summary dependencies
18 -> 19  
3 -> 20  
1..20 -> 21 -> 22 -> 23

### Phase 3 main risks
- screener scope creep
- compatibility mistakes during contract evolution
- late-stage performance work exposing earlier design shortcuts

## Phase 4: Mobile Platform (iOS + Android)
Goal: ship store-ready native apps with bottom navigation, safe areas, push notifications, deep links, and release CI.

### 24. Mobile app shell, safe areas, and bottom navigation
**Frontend**
- implement `mobile_shell.dart` with `BottomNavigationBar` / `NavigationBar`
- wrap screens in `SafeArea`; phone-first single-column layouts; 48dp touch targets
- use `mobile_shell` on iOS/Android; keep `app_shell` for Web if needed

**Dependencies:** Task 5 routing shell  
**Effort:** 1–2 weeks

### 25. Push notifications (FCM + APNs)
**Frontend**
- integrate `firebase_messaging` and `flutter_local_notifications`
- request Android 13+ **`POST_NOTIFICATIONS`** at runtime before showing notifications
- register FCM token with backend immediately after login (and on `onTokenRefresh`)
- handle all three app states:
  - **foreground:** `FirebaseMessaging.onMessage` → local notification or in-app banner
  - **background:** `onBackgroundMessage` (top-level handler with `@pragma('vm:entry-point')`)
  - **terminated:** `getInitialMessage` on cold start; `onMessageOpenedApp` when resumed from notification tray
- Android: high-importance notification channel for price alerts

**Backend**
- migration: `device_push_tokens`
- endpoints: `POST /api/v1/devices/register`, `DELETE /api/v1/devices/:deviceId`
- worker: FCM HTTP v1; extend `notificationChannel` with `PUSH`
- **FCM token hygiene:** delete or deactivate tokens on `UNREGISTERED` / `INVALID_ARGUMENT`; update `last_seen_at` on app open

**Dependencies:** Task 4 auth, Task 14 alerts  
**Effort:** ~1 week

### 26. Deep linking
**Platform**
- `AndroidManifest.xml` intent filters + hosted `assetlinks.json`
- iOS Associated Domains + hosted `apple-app-site-association`
- wire cold-start push taps via `getInitialMessage` → `go_router`

**Dependencies:** Task 5 routing  
**Effort:** 2–4 days

### 27. App Store and Play Store submission
- TestFlight + Play internal testing; store assets, privacy policy, data safety forms
- version: `pubspec.yaml` `x.y.z+build` per upload

**Dependencies:** Tasks 24–26, Phase 2 feature-complete on device  
**Effort:** 1–2 weeks (review time)

### Phase 4 summary dependencies
5 -> 24  
4 + 14 -> 25  
5 -> 26  
24 + 25 + 26 + Phase2 -> 27

### 28. Build flavors (dev / staging / prod)
**Frontend**
- define `dev`, `staging`, `prod` with separate `API_BASE_URL` / `SOCKET_BASE_URL` via `--dart-define` or `flutter_flavorizr`
- separate Firebase projects per environment recommended
- document run commands per flavor in alphacues-mvpweb README

**Dependencies:** Task 1  
**Effort:** 1–2 days

### 29. Offline and connectivity UX
**Frontend**
- `connectivity_plus` listener drives global offline banner
- when offline: show cached REST data with stale timestamp; disable mutating actions where unsafe
- on reconnect: trigger socket reconnect + REST refresh (same path as Task 9)
- align per-screen offline/degraded cells with ARCHITECTURE.md state table

**Dependencies:** Tasks 5, 9  
**Effort:** 2–4 days

### Phase 4 extended dependencies
1 -> 28  
5 + 9 -> 29

## Rollout and commit strategy
- commit backend and frontend foundation separately
- commit each module backend first, then frontend
- do not merge a frontend feature until the backend fixture contract is frozen
- keep migration files in dedicated commits
- run contract tests before every feature merge

## Global blocker checklist
- live provider keys missing: use mock adapters and Mailpit/console email
- Redis unavailable locally: frontend work may continue against read-only mocked API, but backend auth tests must still run against Redis
- market provider quota exhaustion: use recorded fixtures for CI and development
- websocket instability in staging: keep REST fallback fully functional and treat live updates as enhancement, not correctness layer
- no Apple Developer / Play Console account: blocks TestFlight and store push on real devices
- missing macOS CI or signing certs: blocks `flutter build ipa`
- Firebase project not configured: blocks FCM on both platforms
