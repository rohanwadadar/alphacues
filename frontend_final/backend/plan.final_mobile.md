# Alpha Cues MVP Final Blueprint — Mobile Edition

> **Source:** Derived from `alphacues_mvp_design_86b7618e_final.plan.md` (unchanged sections preserved verbatim).  
> **Mobile variant:** `plan.final_mobile.md` — web-to-native (iOS + Android) conversion.  
> **Change tag:** All mobile-specific additions, updates, and deletions are marked **`[Mobile_5_17_26]`**. Search the document for that tag to review only mobile deltas.

**[Mobile_5_17_26] Mobile conversion summary**

| Area | Web (original) | Mobile (this document) |
|---|---|---|
| Client targets | Flutter Web on Vercel | Flutter iOS + Android (App Store + Play Store) |
| Auth token storage | Browser storage | `flutter_secure_storage` |
| Navigation shell | Sidebar / top-nav web shell | `BottomNavigationBar` + platform back gesture |
| Push | In-app + email only | In-app + email + **FCM (Android)** + **APNs via FCM (iOS)** |
| Deep links | Path URLs in browser | Universal/App Links + `go_router` + `AndroidManifest.xml` / `Info.plist` |
| CI release | Web static build | `flutter build apk` / `flutter build appbundle` / `flutter build ipa` |
| Android toolchain | N/A | **compileSdk / targetSdk 36** (Play policy for 2026) |

This file merges the generated project artifacts into one detailed reference document so the MVP can be reviewed from a single place:
- `ARCHITECTURE.md`
- `IMPLEMENTATION_PLAN.md`
- `README.md`
- `docker-compose.yml`

It preserves the target canon already established:
- Flask-owned email OTP auth
- `/api/v1` as the canonical public API
- `Authorization: Bearer <JWT>`
- shared API response envelope
- preserved table and field vocabulary such as `otp_tokens`, `portfolio_event`, `stock_tick`, `watchlist_items`, `BUY`, `SELL`, `ABOVE`, `BELOW`, `PERCENT_CHANGE`

---

## 1. Architecture

### 1.1 System Overview
Alpha Cues is a production-ready stock market alert and notification MVP built as a **modular monolith**: one Flutter client (**Web + iOS + Android**; this mobile edition targets **native iOS and Android**), one Flask backend, one primary PostgreSQL database, and one Redis instance for caching, pub-sub, and background-job transport. The system is optimized for fast MVP iteration while remaining safe to operate for roughly **3,000 to 5,000 concurrent users**.

**[Mobile_5_17_26]** The same Flutter codebase may retain a **web** target for admin or marketing, but the **primary MVP ship target** for this document is **native mobile stores**, not a browser-only deployment.

The architecture keeps strict module boundaries:
- one deployable backend application
- one shared database schema, but tables grouped by module ownership
- no module imports another module's internal files directly
- every cross-module call goes through the owning module's exported service API
- feature flags keep runtime behavior swappable without changing the upstream contract

**Deployment topology**
- `frontend-web` *(optional)*: Flutter Web static build on Vercel
- **`[Mobile_5_17_26]` `frontend-mobile`**: Flutter **iOS** (TestFlight → App Store) and **Android** (internal testing → Play Store) release artifacts; not served as static HTML
- `backend-api`: Flask REST API + Socket.IO gateway on Railway
- `backend-worker`: Celery worker on Railway
- `backend-scheduler`: Celery Beat or APScheduler process on Railway
- `backend-streamer`: dedicated long-lived market-stream consumer on Railway
- `postgres`: single Railway PostgreSQL database
- `redis`: single Railway Redis instance

**External integrations**
- `Alpaca`: real-time price stream and quote/history data
- `Alpha Vantage`: fundamentals and fallback market metadata
- `SendGrid`: transactional OTP email delivery
- **`[Mobile_5_17_26]` `Firebase Cloud Messaging (FCM)`**: push delivery to Android; iOS delivery via FCM → APNs
- **`[Mobile_5_17_26]` `Apple Push Notification service (APNs)`**: required for iOS; configure APNs Auth Key (`.p8`) in Firebase and Apple Developer

**[Mobile_5_17_26] App Store / Play Store deployment pipeline (high level)**

1. **Developer accounts:** Apple Developer Program ($99/yr), Google Play Console (one-time fee).
2. **Signing:** iOS — certificates, provisioning profiles, App ID with Push Notifications capability; Android — upload keystore (Play App Signing recommended).
3. **CI builds:** `flutter build appbundle --release` (Play preferred over raw APK for production), `flutter build ipa --release` (or `flutter build ios` + Xcode archive on macOS runner).
4. **Internal testing:** TestFlight (iOS), Play internal / closed testing (Android).
5. **Store assets:** icons, screenshots (6.7" / 6.5" iPhone, phone + tablet Android), privacy policy URL, data-safety / App Privacy questionnaires.
6. **Submission:** App Store Connect + Play Console review; plan **1–2 weeks** first-review buffer.
7. **Post-release:** staged rollout (Play %), phased release (App Store), crash monitoring (Firebase Crashlytics or Sentry Flutter).

**Operational goals**
- REST is the source of truth; WebSocket is an incremental live-update layer
- all API responses follow a single shared envelope
- feature flags are stored in the `feature_flags` table and can change behavior without deployment
- Redis is treated as a performance layer, not the only source of truth for critical business events
- critical side effects use a database outbox so Redis or worker failures do not silently lose alerts or notifications

```mermaid
flowchart TD
  FlutterWeb[FlutterWeb_Optional]
  FlutterMobile[FlutterMobile_iOS_Android]
  FlutterWeb -->|"REST /api/v1"| FlaskApi[FlaskApi]
  FlutterMobile -->|"REST /api/v1"| FlaskApi
  FlutterWeb -->|"Socket.IO /stream"| RealtimeGateway[RealtimeGateway]
  FlutterMobile -->|"Socket.IO /stream"| RealtimeGateway
  FlutterMobile -->|"FCM token register"| FlaskApi
  WorkerProc -->|"FCM/APNs send"| FCM[FirebaseFCM]
  FCM --> FlutterMobile
  FlaskApi --> PostgresDb[Postgres]
  FlaskApi --> RedisLayer[Redis]
  FlaskApi --> SendGridSvc[SendGrid]
  FlaskApi --> MarketAdapters[AlpacaAndAlphaVantage]
  RealtimeGateway --> RedisLayer
  WorkerProc[Worker] --> PostgresDb
  WorkerProc --> RedisLayer
  SchedulerProc[Scheduler] --> PostgresDb
  SchedulerProc --> RedisLayer
  StreamerProc[Streamer] --> MarketAdapters
  StreamerProc --> RedisLayer
  StreamerProc --> PostgresDb
```

**Security and reliability baseline**
- OTP auth with email normalization, hashed OTP storage, expiry, attempt tracking, and lockouts
- short-lived access JWT plus refresh token rotation
- SQLAlchemy and parameterized queries only
- endpoint-specific rate limiting
- structured logs with request IDs
- Sentry-ready error reporting
- health/readiness endpoints and queue-lag monitoring
- retry with exponential backoff for external providers

### 1.2 Frontend Structure
The frontend is a **Flutter** application (Web + **iOS + Android** for this mobile edition) designed for fast iteration, responsive dashboards, and contract-safe integration with the Flask API. It uses `go_router` for navigation, Riverpod for state management, `dio` for HTTP, and Socket.IO for live quotes and notifications.

**[Mobile_5_17_26] Platform targets and packages**

| Concern | Package / approach |
|---|---|
| Secure token storage | `flutter_secure_storage` (replaces web `browser_storage` on mobile) |
| Push notifications | `firebase_core`, `firebase_messaging` |
| Local notifications (foreground display) | `flutter_local_notifications` |
| Deep links | `go_router` deep link support + `app_links` (optional) + platform manifest config |
| Device info / OS version | `device_info_plus`, `package_info_plus` |
| Connectivity / offline | `connectivity_plus` |
| Haptics (optional) | `flutter_haptics` or platform channels |
| Crash reporting | `sentry_flutter` or `firebase_crashlytics` |
| App icon / splash | `flutter_launcher_icons`, `flutter_native_splash` |

**[Mobile_5_17_26] Mobile-specific UI considerations**

- **Safe areas:** Wrap primary screen bodies in `SafeArea` (or `Scaffold` with `resizeToAvoidBottomInset`) so content does not sit under the iPhone notch, Dynamic Island, or Android gesture/nav bars.
- **Touch targets:** Minimum **48×48 logical pixels** for tappable controls (Material); avoid hover-only affordances from web.
- **Navigation:** Replace web sidebar/top-nav with **`BottomNavigationBar`** (4–5 primary tabs: Dashboard, Watchlists, Alerts, Portfolio; Screener gated by flag). Use **`NavigationBar`** (Material 3) on Android and Cupertino tab patterns where appropriate for iOS sub-flows.
- **Back behavior:** Honor Android system back and iOS swipe-back via `go_router` stack; avoid web-only `pop` assumptions.
- **Keyboard:** OTP and form screens must scroll above the keyboard (`SingleChildScrollView` + `viewInsets`).
- **Charts:** Prefer pan/zoom gestures over mouse hover tooltips; larger hit areas on timeframe chips.
- **Biometrics (post-MVP optional):** Local auth to unlock app after background — not required for MVP but reserve `local_auth` hook.
- **Orientation:** Lock portrait for MVP unless tablet layout is explicitly designed.
- **Text scaling:** Test with system font scale up to 1.3×; avoid fixed-height rows that clip prices.

**[Mobile_5_17_26] Responsive layout strategy (mobile-first)**

| Breakpoint | Layout |
|---|---|
| Phone (&lt; 600dp) | Single column, bottom nav, full-width cards |
| Tablet (600–900dp) | Optional two-column dashboard; still bottom or rail nav |
| Desktop / Web (optional) | Retain original sidebar shell if web target ships |

**[Mobile_5_17_26] PWA note:** A **Progressive Web App** (service worker + `manifest.json`) is **out of scope** for native store delivery. If a lightweight web install is needed later, treat PWA as a **separate 2–3 day spike**, not a substitute for App Store / Play Store binaries.

#### UI and design system
- font: `Inter`
- primary CTA color: `#7061F3`
- background: `#FFFFFF`
- surface/background-alt: `#F8F9FA`
- uptrend color: green
- downtrend color: red
- spacing: 8px grid
- design direction: modern, clean, investor-friendly, mobile-first, still professional on desktop

#### Planned frontend folder structure
```text
frontend/
  lib/
    main.dart
    app/
      app.dart
      router/
        app_router.dart
        route_guards.dart
      theme/
        app_theme.dart
        app_colors.dart
        app_spacing.dart
        app_typography.dart
    core/
      config/
        app_config.dart
      network/
        api_client.dart
        api_envelope.dart
        api_error.dart
        retry_policy.dart
      auth/
        auth_session.dart
        auth_token_store.dart
        auth_interceptor.dart
      realtime/
        socket_client.dart
        socket_events.dart
        quote_subscription_manager.dart
      storage/
        browser_storage.dart          # web only
        secure_token_store.dart       # [Mobile_5_17_26] mobile: flutter_secure_storage
      push/                           # [Mobile_5_17_26]
        push_service.dart
        push_token_repository.dart
        notification_tap_handler.dart
      platform/                       # [Mobile_5_17_26]
        platform_info.dart
        connectivity_service.dart
      widgets/
        app_shell.dart                # web: sidebar shell
        mobile_shell.dart             # [Mobile_5_17_26] BottomNavigationBar shell
        loading_skeleton.dart
        empty_state.dart
        error_state.dart
        stale_banner.dart
        safe_screen.dart              # [Mobile_5_17_26] SafeArea wrapper
    features/
      auth/
      dashboard/
      market/
      watchlist/
      alerts/
      notifications/
      portfolio/
      screener/
    test/
  android/                            # [Mobile_5_17_26]
    app/
      build.gradle.kts
      src/main/AndroidManifest.xml
      google-services.json
  ios/                                # [Mobile_5_17_26]
    Runner/
      Info.plist
      Runner.entitlements
      GoogleService-Info.plist
```

#### Navigation and routing map
`go_router` uses path-based URLs and a single authenticated shell route. Public routes stay small; authenticated routes are deep-linkable.

**[Mobile_5_17_26] Deep linking configuration**

`go_router` route paths stay **unchanged**; platform files wire HTTPS / custom-scheme URLs into the same paths.

**Universal link / app link host (example):** `https://app.alphacues.com`

| App path | Deep link example |
|---|---|
| `/verify-otp` | `https://app.alphacues.com/verify-otp?challengeId=...` |
| `/symbols/AAPL` | `https://app.alphacues.com/symbols/AAPL` |
| `/watchlists/42` | `https://app.alphacues.com/watchlists/42` |
| `/alerts` | `https://app.alphacues.com/alerts` |

**Android — `android/app/src/main/AndroidManifest.xml` (inside `MainActivity`):**
```xml
<!-- [Mobile_5_17_26] -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="app.alphacues.com" />
</intent-filter>
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="alphacues" android:host="open" />
</intent-filter>
```

Host **`/.well-known/assetlinks.json`** on the marketing/API domain for Android App Links verification.

**iOS — `ios/Runner/Runner.entitlements`:**
```xml
<!-- [Mobile_5_17_26] -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:app.alphacues.com</string>
</array>
```

Host **`/.well-known/apple-app-site-association`** (no file extension) for Universal Links.

**Push notification deep links:** FCM `data` payload includes `deepLink` (e.g. `/symbols/AAPL`); `notification_tap_handler.dart` calls `GoRouter.go(deepLink)` on cold start (`getInitialMessage`) and warm resume (`onMessageOpenedApp`).

**[Mobile_5_17_26] Bottom navigation map (authenticated shell)**

| Tab index | Label | Root path | Notes |
|---|---|---|---|
| 0 | Home | `/dashboard` | |
| 1 | Watchlists | `/watchlists` | |
| 2 | Alerts | `/alerts` | badge for unread |
| 3 | Portfolio | `/portfolio` | |
| — | Screener | `/screener` | hidden when `enable_screener=false`; optional 5th tab or overflow menu |

Symbol detail (`/symbols/:symbol`) and watchlist detail remain **stack pushes** above the shell, not separate bottom tabs.

| Path | Screen | Auth | Notes |
|---|---|---|---|
| `/` | redirect | mixed | `/dashboard` if authenticated, else `/login` |
| `/login` | email entry | public | send OTP |
| `/verify-otp` | OTP verification | public | accepts `challengeId` query param |
| `/dashboard` | home dashboard | private | overview, top movers, watchlist summary |
| `/watchlists` | watchlist list | private | empty state includes create CTA |
| `/watchlists/:watchlistId` | watchlist detail | private | prices, add/remove symbols |
| `/symbols/:symbol` | symbol detail | private | chart, quote, fundamentals, alert CTA |
| `/alerts` | alerts and notifications | private | active alerts, history, unread state |
| `/portfolio` | portfolio summary | private | manual holdings for MVP |
| `/screener` | strategy and screener | private | gated by `enable_screener` |
| `*` | not found | mixed | redirect to a safe route |

#### Riverpod provider hierarchy
The frontend must avoid tangled auth state. The provider graph is explicit:

1. `appConfigProvider`
   Reads API base URL, feature toggles for local mock mode, and environment settings.
2. `browserStorageProvider` *(web only)*
   Owns secure-ish browser storage abstraction for tokens and cached read models.
2b. **`[Mobile_5_17_26]` `secureTokenStoreProvider`**
   Wraps `flutter_secure_storage` for access/refresh tokens on iOS Keychain and Android EncryptedSharedPreferences.
3. `authRepositoryProvider`
   Talks only to auth endpoints.
4. `authSessionProvider`
   Canonical session state:
   - `null` means logged out
   - `AuthSession` contains access token, refresh token, expiry, and user object
   - methods: `sendOtp`, `verifyOtp`, `refreshTokens`, `logout`
5. `apiClientProvider`
   Injects `Authorization: Bearer <JWT>` for authenticated requests and centralizes error mapping.
6. `socketClientProvider`
   Owns one socket connection per authenticated session (browser or mobile app instance).
6b. **`[Mobile_5_17_26]` `pushServiceProvider`**
   Registers FCM token with backend after login; refreshes token on `onTokenRefresh`; clears registration on logout.
7. Feature repository providers
   `dashboardRepositoryProvider`, `watchlistRepositoryProvider`, `alertsRepositoryProvider`, `portfolioRepositoryProvider`, `screenerRepositoryProvider`, `marketRepositoryProvider`
8. Feature controller providers
   Own `AsyncValue` screens and mutation flows.

#### Token refresh and logout propagation
- Access token expiry returns `401 TOKEN_EXPIRED`
- `dio` interceptor uses a **single-flight refresh lock** so only one refresh request runs at a time
- queued requests wait for that refresh result and replay once on success
- on refresh failure:
  - persisted tokens are cleared
  - socket is disconnected
  - all user-scoped providers are invalidated
  - router redirects to `/login`

#### Realtime behavior
- one Socket.IO connection per authenticated session
- namespace: `/stream`
- initial page load always comes from REST
- socket updates only visible symbols plus notification events
- after reconnect, client re-subscribes and refetches REST snapshots before clearing the stale banner

#### Offline, loading, empty, and error states
Every major screen must render one of: loading, data, empty, error, or degraded/offline. Blank screens are not allowed.

| Screen | Loading | Empty | Error | Offline / degraded |
|---|---|---|---|---|
| Dashboard | skeleton cards and chart placeholders | create first watchlist CTA | retry banner plus per-widget fallback | show cached snapshot with stale timestamp |
| Watchlists | list skeleton | "No watchlists yet" | page-level retry | read cached watchlists, disable mutating actions if needed |
| Watchlist detail | row skeletons | "Add symbols to start tracking" | inline row errors plus top retry | stale price badges |
| Symbol detail | chart placeholder | invalid symbol routes to not found | market-data unavailable state | show last known candle and quote timestamp |
| Alerts | list skeleton | "No alerts yet" | form/list errors inline | pause live badge if socket is down |
| Portfolio | holdings skeleton | "No holdings yet" | retry | use last known prices with stale note |
| Screener | filter placeholder and table skeleton | "No matches" after a completed run | preserve filters and show retry | view last saved preset but disable fresh scans |

#### Frontend testing approach
- provider tests for auth, refresh locking, and logout invalidation
- widget tests for route guards and major loading/empty/error states
- contract tests that parse committed backend JSON fixtures
- limited Chrome E2E flows for login, watchlist, alerts, and reconnect behavior
- **`[Mobile_5_17_26]`** integration tests: `integration_test/` on Android emulator + iOS simulator (login, bottom nav, deep link cold start)
- **`[Mobile_5_17_26]`** device matrix: at least one physical iPhone (notch) and one physical Android (API 34+); release-mode smoke: `flutter run --release`
- **`[Mobile_5_17_26]`** push: manual TestFlight / internal track verification for foreground, background, and terminated tap-to-navigate

**[Mobile_5_17_26] Android SDK / toolchain requirements**

In `android/app/build.gradle.kts` (or `build.gradle`):

```kotlin
// [Mobile_5_17_26] Google Play 2026 policy: target API 36 (Android 16)
android {
    compileSdk = 36
    defaultConfig {
        minSdk = 24        // Android 7.0+; adjust only with product approval
        targetSdk = 36
    }
}
```

- Install **Android SDK Platform 36** and latest build-tools via Android Studio SDK Manager.
- Use **JDK 17** (Flutter 3.16+ default).
- **Android 13+ (API 33):** request `POST_NOTIFICATIONS` at runtime before showing notifications.
- CI image: `ghcr.io/cirruslabs/flutter` or `subosito/flutter-action` with pre-installed SDK 36.

**[Mobile_5_17_26] iOS toolchain requirements**

- **Xcode 15+** (16 recommended for latest iOS SDK).
- **Minimum deployment target:** iOS 13.0+ (recommend **15.0** for broader Swift/Flutter plugin support).
- Enable capabilities: **Push Notifications**, **Associated Domains** (Universal Links).
- CocoaPods: run `pod install` in `ios/` after `flutter pub get`.

**[Mobile_5_17_26] Release build commands**

```bash
# Android — Play Store (preferred)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android

# Android — sideload / internal QA APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android

# iOS — requires macOS + signing
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info/ios
# Alternative: flutter build ios --release then Archive in Xcode
```

### 1.3 Backend Structure
The backend is a Flask modular monolith that owns the business contract, auth lifecycle, persistence model, and realtime fan-out. Each module owns its tables, service layer, routes, schemas, and tests. Cross-module access is allowed only through exported service APIs.

#### Planned backend folder structure
```text
backend/
  app/
    __init__.py
    extensions.py
    config/
      base.py
      development.py
      production.py
      testing.py
    modules/
      user/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
      portfolio/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
      market/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
      watchlist/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
      alerts/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
      notifications/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
      screener/
        __init__.py
        routes.py
        service.py
        models.py
        schemas.py
        tests/
    shared/
      db.py
      cache.py
      limiter.py
      logging.py
      error_handler.py
      auth.py
      feature_flags.py
      response.py
      pagination.py
      validators.py
      websocket.py
    adapters/
      protocols.py
      market_data.py
      fake_market_data.py
      email_sender.py
      fake_email_sender.py
  migrations/
  worker.py
  scheduler.py
  streamer.py
  wsgi.py
  tests/
```

#### Module ownership and public services
- `user`: `UserService`, `SessionService`
- `portfolio`: `PortfolioService`
- `market`: `MarketService`
- `watchlist`: `WatchlistService`
- `alerts`: `AlertsService`, `AlertEvaluationService`
- `notifications`: `NotificationService`
- `screener`: `ScreenerService`
- `shared`: `FeatureFlagService`, `CacheService`, `ResponseFactory`

**Boundary rule**
- allowed: `from app.modules.watchlist.service import WatchlistService`
- not allowed: direct imports into another module's `models.py` or internal helper files

#### Process responsibilities
- `backend-api`
  - serves `/api/v1/*`
  - validates JWT
  - serves Socket.IO namespace `/stream`
  - exposes `/health/live` and `/health/ready`
- `backend-worker`
  - sends OTP emails
  - processes outbox events
  - marks notifications delivered
  - runs slower async work
  - **`[Mobile_5_17_26]`** sends push notifications via FCM HTTP v1 API (Android + iOS)
- `backend-scheduler`
  - OTP cleanup
  - alert reconciliation
  - cache warmers
  - periodic backfills
- `backend-streamer`
  - owns upstream Alpaca real-time connection
  - normalizes ticks
  - stores latest prices
  - publishes quote updates

#### Auth design
Flask owns auth. Supabase is intentionally excluded from the runtime path to keep a single business/API contract and one primary database.

**Flow**
1. user requests OTP with email
2. backend creates or reuses a `users` row and inserts an `otp_tokens` challenge row
3. OTP is hashed at rest and sent by SendGrid
4. user submits OTP plus `otpChallengeId`
5. backend verifies the challenge, enforces attempt limits, issues access and refresh tokens, and returns the canonical user object

**Edge cases**
- OTP expires after 5 minutes
- 5 wrong attempts lock email + IP for 15 minutes
- resend is rate-limited and invalidates previous unused challenge
- generic messaging reduces account enumeration

#### Realtime architecture
- client connection: Socket.IO namespace `/stream`
- upstream source: Alpaca quote stream
- internal fan-out: Redis pub-sub for non-critical live updates
- drift correction: client refreshes REST state after reconnect
- durability: alert outcomes and notifications are first written to Postgres before any websocket push

#### Reliability design
- Redis cache TTLs:
  - quotes: 3 to 5 seconds
  - watchlist summary: 15 to 30 seconds
  - chart bars: 1 to 5 minutes
  - fundamentals: 1 to 6 hours
- retries:
  - external APIs use exponential backoff with jitter
  - side-effecting tasks must be idempotent
- rate limits:
  - OTP request: `5/minute/IP`, `3/15 minutes/email`
  - OTP verify: lock on the 5th wrong attempt
  - market search: `30/minute/user`
  - batch quote reads capped by symbol count

#### Local development without live keys
Use adapters and environment flags:
- `MOCK_EXTERNAL_SERVICES=true`
- `EMAIL_BACKEND=console` or `smtp`
- fake market data fixtures for Alpaca and Alpha Vantage
- console OTP or Mailpit for dev email

This keeps auth and dashboard flows testable before any live provider key is added.

### 1.4 API Design
#### Canonical API rules
- public base path: `/api/v1`
- auth header: `Authorization: Bearer <JWT>`
- content type: `application/json`
- timestamps: ISO-8601 UTC, example `2026-05-13T17:15:30Z`
- numeric precision:
  - API numbers may be serialized as JSON numbers
  - stored money and price values use `NUMERIC(18,6)`
- ID format:
  - `userId`, `watchlistId`, `alertId`, `notificationId`, `portfolioId` are decimal strings backed by `BIGSERIAL`
  - `eventId` and request IDs are UUID strings
- symbol format:
  - uppercase ticker strings, `^[A-Z][A-Z0-9._-]{0,14}$`

#### Response envelope contract
**Success**
```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": {
    "requestId": "e5f22e08-a2a4-4d82-b8cd-1f7c3e7d1c5f",
    "apiVersion": "1"
  }
}
```

**Error**
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "OTP_EXPIRED",
    "message": "This code expired. Request a new one.",
    "details": {}
  },
  "meta": {
    "requestId": "e5f22e08-a2a4-4d82-b8cd-1f7c3e7d1c5f",
    "apiVersion": "1"
  }
}
```

#### Error contract
| Condition | HTTP | `error.code` |
|---|---:|---|
| invalid input | 422 | `VALIDATION_ERROR` |
| missing or bad JWT | 401 | `UNAUTHORIZED` |
| expired access token | 401 | `TOKEN_EXPIRED` |
| wrong OTP | 401 | `OTP_INVALID` |
| expired OTP | 401 | `OTP_EXPIRED` |
| unknown challenge | 404 | `OTP_CHALLENGE_NOT_FOUND` |
| too many OTP attempts | 429 | `OTP_LOCKED` |
| endpoint rate limited | 429 | `RATE_LIMITED` |
| duplicate symbol in watchlist | 409 | `DUPLICATE_SYMBOL` |
| feature flag disabled | 403 | `FEATURE_DISABLED` |
| upstream timeout | 504 | `UPSTREAM_TIMEOUT` |
| degraded dependency | 503 | `SERVICE_UNAVAILABLE` |

#### Auth contract
**JWT claims**
- `sub`: `userId`
- `email`: normalized email
- `sid`: session identifier
- `typ`: `access` or `refresh`
- `iat`, `exp`

**Session policy**
- access token TTL: 15 minutes
- refresh token TTL: 7 days
- refresh rotates on every successful refresh
- refresh failure logs the user out

**Endpoints**
| Method | Endpoint | Notes |
|---|---|---|
| `POST` | `/api/v1/auth/send-otp` | request OTP to email |
| `POST` | `/api/v1/auth/verify-otp` | verify OTP and issue tokens |
| `POST` | `/api/v1/auth/refresh` | refresh access and refresh tokens |
| `POST` | `/api/v1/auth/logout` | revoke session and clear refresh token |
| `GET` | `/api/v1/auth/verify` | verify current access token |
| `GET` | `/api/v1/auth/me` | current user profile |
| `PUT` | `/api/v1/auth/me` | update display name and avatar URL |

**Request and response shapes**
- `POST /api/v1/auth/send-otp`
  - request body: `{ "email": "user@example.com" }`
  - success data:
    ```json
    {
      "otpChallengeId": "8f38ef28-6b85-44c1-b1e5-06658ff52e4f",
      "emailMasked": "u***@example.com",
      "expiresInSeconds": 300
    }
    ```
- `POST /api/v1/auth/verify-otp`
  - request body: `{ "email": "user@example.com", "otpChallengeId": "uuid", "otpCode": "123456" }`
  - success data:
    ```json
    {
      "accessToken": "jwt",
      "refreshToken": "jwt",
      "expiresInSeconds": 900,
      "user": {
        "userId": "123",
        "email": "user@example.com",
        "name": "Alex",
        "avatarUrl": null
      }
    }
    ```

#### Market and dashboard contract
**Canonical query parameters**
- `symbol`
- `symbols`
- `q`
- `timeframe`
- `limit`
- `cursor`
- `sort`
- `range`

**Timeframe and range rules**
- `timeframe` means bar granularity only:
  - `5min`, `15min`, `30min`, `1hour`, `1day`, `1week`, `1month`
- `range` means chart period:
  - `1D`, `1W`, `1M`, `3M`, `6M`, `1Y`, `5Y`, `MAX`

**Endpoints**
| Method | Endpoint | Notes |
|---|---|---|
| `GET` | `/api/v1/market/quote?symbol=AAPL` | latest quote |
| `GET` | `/api/v1/market/bars?symbol=AAPL&timeframe=5min&range=1D` | OHLCV bars |
| `GET` | `/api/v1/market/snapshot?symbols=AAPL,TSLA` | batch snapshot |
| `GET` | `/api/v1/market/search?q=apple&limit=10` | search/autocomplete |
| `GET` | `/api/v1/market/movers?sort=gainers&limit=10` | dashboard movers |
| `GET` | `/api/v1/market/fundamentals?symbol=AAPL` | company fundamentals |
| `GET` | `/api/v1/dashboard` | dashboard aggregate payload |

**Bar contract**
```json
{
  "symbol": "AAPL",
  "bars": [
    {
      "timeStamp": "2026-05-13T14:30:00Z",
      "openPrice": 188.120000,
      "highPrice": 189.020000,
      "lowPrice": 187.980000,
      "closePrice": 188.900000,
      "volume": 1823400
    }
  ]
}
```

#### Watchlist contract
| Method | Endpoint | Notes |
|---|---|---|
| `GET` | `/api/v1/watchlist` | list watchlists |
| `POST` | `/api/v1/watchlist` | create watchlist |
| `GET` | `/api/v1/watchlist/:id` | watchlist detail |
| `PUT` | `/api/v1/watchlist/:id` | rename watchlist |
| `DELETE` | `/api/v1/watchlist/:id` | delete watchlist |
| `POST` | `/api/v1/watchlist/:id/items` | add symbol |
| `DELETE` | `/api/v1/watchlist/:id/items/:symbol` | remove symbol |

**Domain semantics**
- a `watchlist item` is a unique symbol within one watchlist
- duplicate symbols are rejected with `409 DUPLICATE_SYMBOL`
- watchlists are user-owned only; no shared watchlists in MVP

#### Alerts and notifications contract
| Method | Endpoint | Notes |
|---|---|---|
| `GET` | `/api/v1/alerts` | list alerts |
| `POST` | `/api/v1/alerts` | create alert |
| `PUT` | `/api/v1/alerts/:id` | update alert |
| `DELETE` | `/api/v1/alerts/:id` | delete alert |
| `GET` | `/api/v1/alerts/history` | triggered-alert history |
| `GET` | `/api/v1/notifications` | notification feed |
| `PUT` | `/api/v1/notifications/:id/read` | mark read |
| `PUT` | `/api/v1/notifications/read-all` | mark all read |

**Enum contract**
- `action`: `BUY`, `SELL`
- `condition`: `ABOVE`, `BELOW`, `PERCENT_CHANGE`
- `notificationChannel`: `IN_APP`, `EMAIL`, **`PUSH`** `[Mobile_5_17_26]`

**[Mobile_5_17_26] Push notification API (additive)**

| Method | Endpoint | Notes |
|---|---|---|
| `POST` | `/api/v1/devices/register` | Register or update FCM device token |
| `DELETE` | `/api/v1/devices/:deviceId` | Unregister on logout |
| `PUT` | `/api/v1/devices/:deviceId/preferences` | Opt in/out of push per category (optional MVP: global on/off) |

**`POST /api/v1/devices/register` request body (example):**
```json
{
  "fcmToken": "string",
  "platform": "ios",
  "appVersion": "1.0.0",
  "deviceId": "client-generated-uuid"
}
```

**FCM `data` payload for alert triggers (example):**
```json
{
  "deepLink": "/symbols/AAPL",
  "notificationId": "456",
  "alertId": "123"
}
```

**Business rules**
- `alert triggered` means the latest evaluated market price crosses the alert threshold from the non-triggered side while the alert is active and outside any cooldown window
- one alert should not generate duplicate notifications for the same evaluation window
- an alert can be re-armed if edited or re-enabled

#### Portfolio contract
| Method | Endpoint | Notes |
|---|---|---|
| `GET` | `/api/v1/portfolio` | portfolio summary |
| `GET` | `/api/v1/portfolio/history` | portfolio performance |
| `GET` | `/api/v1/portfolio/transactions` | BUY/SELL event ledger |
| `POST` | `/api/v1/portfolio/event` | record BUY/SELL event |
| `PUT` | `/api/v1/portfolio/event/:id` | edit manual event before settlement window closes |
| `DELETE` | `/api/v1/portfolio/event/:id` | delete manual event if allowed |

**Domain semantics**
- `BUY/SELL event` means a user-recorded portfolio transaction in the MVP, not a broker-executed order
- `portfolio total` / `totalValue` means current marked-to-market value of all current positions
- `availableBalance` is present for contract compatibility and defaults to `0.000000` until cash tracking is introduced

**Portfolio summary shape**
```json
{
  "portfolioId": "12",
  "totalValue": 12500.500000,
  "availableBalance": 0.000000,
  "totalProfit": 500.500000,
  "totalReturn": 4.170000,
  "dayChange": -125.220000,
  "asOf": "2026-05-13T14:30:00Z"
}
```

#### Screener contract
| Method | Endpoint | Notes |
|---|---|---|
| `GET` | `/api/v1/screener/strategies` | saved strategies |
| `POST` | `/api/v1/screener/strategies` | save strategy |
| `DELETE` | `/api/v1/screener/strategies/:id` | delete strategy |
| `POST` | `/api/v1/screener/run` | execute a screen |

#### Pagination, sorting, filtering, and idempotency
- list endpoints return `meta.nextCursor`
- `limit` defaults to 20, max 100 unless the endpoint documents otherwise
- `sort` uses explicit enums per endpoint, not free-form SQL-like fields
- mutations support an optional `Idempotency-Key` header for retry-safe create operations such as `send-otp`, `create alert`, and `record portfolio event`

#### Backward compatibility rules
- `/api/v1` is canonical
- older `/api/*` paths from the current proxy backend can stay as legacy aliases during migration, but no old path is silently repurposed to new semantics
- breaking changes require `/api/v2`
- additive fields are allowed in `v1`
- deprecated fields remain for at least one frontend release window

#### Realtime contract
**Namespace**
- Socket.IO namespace: `/stream`

**Client events**
- `subscribe_quotes`
- `unsubscribe_quotes`
- `subscribe_notifications`
- `resume_session`

**Server events**
- `quote_update`
- `notification_new`
- `alert_triggered`
- `connection_state`
- `error`

**`quote_update` payload**
```json
{
  "symbol": "AAPL",
  "lastPrice": 188.900000,
  "changeAmount": 1.240000,
  "changePercent": 0.661200,
  "asOf": "2026-05-13T14:30:01Z"
}
```

**`notification_new` payload**
```json
{
  "notificationId": "456",
  "alertId": "123",
  "title": "AAPL crossed above 190.00",
  "body": "Your AAPL ABOVE alert was triggered.",
  "createdAt": "2026-05-13T14:30:02Z"
}
```

### 1.5 Database Design
The primary database is PostgreSQL. Table and column names preserve the current backend structure document wherever possible. Schema evolution is additive-first.

#### Database relationship diagram
```mermaid
erDiagram
    users ||--o{ otp_tokens : has
    users ||--o{ user_sessions : owns
    users ||--o{ watchlists : owns
    watchlists ||--o{ watchlist_items : contains
    users ||--o{ portfolio_event : records
    users ||--o{ positions : holds
    users ||--o{ portfolio_snapshot : snapshots
    users ||--o{ alerts : creates
    alerts ||--o{ notifications : generates
    alerts ||--o{ alert_trigger_events : triggers
    users ||--o{ notifications : receives
    users ||--o{ screener_strategies : saves

    users {
      BIGSERIAL user_id PK
      TEXT email UK
      TEXT name
      TEXT avatar_url
      BOOLEAN is_active
      TIMESTAMPTZ created_at
      TIMESTAMPTZ updated_at
    }

    otp_tokens {
      BIGSERIAL id PK
      UUID challenge_id UK
      BIGINT user_id FK
      TEXT email
      TEXT otp_hash
      TIMESTAMPTZ expires_at
      BOOLEAN used
      INTEGER failed_attempts
      TIMESTAMPTZ locked_until
    }

    user_sessions {
      UUID session_id PK
      BIGINT user_id FK
      TEXT refresh_token_hash
      TIMESTAMPTZ expires_at
      TIMESTAMPTZ revoked_at
    }

    watchlists {
      BIGSERIAL watchlist_id PK
      BIGINT user_id FK
      TEXT name
      TIMESTAMPTZ created_at
    }

    watchlist_items {
      BIGSERIAL id PK
      BIGINT watchlist_id FK
      TEXT symbol
      TIMESTAMPTZ added_at
    }

    portfolio_event {
      UUID event_id PK
      TIMESTAMPTZ time_stamp
      BIGINT user_id FK
      TEXT symbol
      TEXT action
      NUMERIC price
      INTEGER volume
    }

    positions {
      BIGINT user_id FK
      TEXT symbol PK
      INTEGER volume
      NUMERIC total_price
      TIMESTAMPTZ updated_at
    }

    portfolio_snapshot {
      BIGINT user_id FK
      TIMESTAMPTZ time_stamp PK
      TEXT symbol PK
      BIGINT quantity
      NUMERIC total_price
    }

    stock_tick {
      TEXT symbol PK
      TIMESTAMPTZ time_stamp PK
      NUMERIC open_price
      NUMERIC high_price
      NUMERIC low_price
      NUMERIC close_price
      BIGINT volume
    }

    alerts {
      BIGSERIAL alert_id PK
      BIGINT user_id FK
      TEXT symbol
      TEXT condition
      NUMERIC target
      BOOLEAN is_active
      BOOLEAN triggered
      INTEGER cooldown_seconds
      TIMESTAMPTZ last_triggered_at
    }

    alert_trigger_events {
      BIGSERIAL id PK
      BIGINT alert_id FK
      TIMESTAMPTZ triggered_at
      NUMERIC trigger_price
    }

    notifications {
      BIGSERIAL notification_id PK
      BIGINT user_id FK
      BIGINT alert_id FK
      TEXT title
      TEXT body
      BOOLEAN is_read
      TIMESTAMPTZ created_at
    }

    screener_strategies {
      BIGSERIAL strategy_id PK
      BIGINT user_id FK
      TEXT name
      JSONB filters
      TIMESTAMPTZ created_at
    }

    feature_flags {
      TEXT flag_key PK
      BOOLEAN is_enabled
      TEXT description
      TIMESTAMPTZ updated_at
    }
```

#### Core module tables
**User and session**
- `users`
  - `user_id BIGSERIAL PRIMARY KEY`
  - `email TEXT NOT NULL UNIQUE`
  - `name TEXT NULL`
  - `avatar_url TEXT NULL`
  - `is_active BOOLEAN NOT NULL DEFAULT TRUE`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `otp_tokens`
  - `id BIGSERIAL PRIMARY KEY`
  - `challenge_id UUID NOT NULL UNIQUE`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `email TEXT NOT NULL`
  - `otp_hash TEXT NOT NULL`
  - `expires_at TIMESTAMPTZ NOT NULL`
  - `used BOOLEAN NOT NULL DEFAULT FALSE`
  - `failed_attempts INTEGER NOT NULL DEFAULT 0`
  - `locked_until TIMESTAMPTZ NULL`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `user_sessions`
  - `session_id UUID PRIMARY KEY`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `refresh_token_hash TEXT NOT NULL`
  - `expires_at TIMESTAMPTZ NOT NULL`
  - `revoked_at TIMESTAMPTZ NULL`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`

**Watchlist**
- `watchlists`
  - `watchlist_id BIGSERIAL PRIMARY KEY`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `name TEXT NOT NULL`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `watchlist_items`
  - `id BIGSERIAL PRIMARY KEY`
  - `watchlist_id BIGINT NOT NULL REFERENCES watchlists(watchlist_id)`
  - `symbol TEXT NOT NULL`
  - `added_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
  - `UNIQUE (watchlist_id, symbol)`

**Portfolio**
- `portfolio_event`
  - `event_id UUID PRIMARY KEY`
  - `time_stamp TIMESTAMPTZ NOT NULL`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `symbol TEXT NOT NULL`
  - `action TEXT NOT NULL CHECK (action IN ('BUY','SELL'))`
  - `price NUMERIC(18,6) NOT NULL`
  - `volume INTEGER NOT NULL`
- `positions`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `symbol TEXT NOT NULL`
  - `volume INTEGER NOT NULL DEFAULT 0`
  - `total_price NUMERIC(18,6) NOT NULL DEFAULT 0`
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
  - `PRIMARY KEY (user_id, symbol)`
- `portfolio_snapshot`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `time_stamp TIMESTAMPTZ NOT NULL`
  - `symbol TEXT NOT NULL`
  - `quantity BIGINT NOT NULL`
  - `total_price NUMERIC(18,6) NOT NULL`
  - `PRIMARY KEY (user_id, time_stamp, symbol)`

**Canonical semantics for portfolio math**
- `positions.total_price` means remaining cost basis of the current open quantity
- on `SELL`, the system reduces `total_price` by weighted average cost, not by sale proceeds
- realized P/L is derived separately; this avoids ambiguous cost-basis math

**Market**
- `stock_tick`
  - `symbol TEXT NOT NULL`
  - `time_stamp TIMESTAMPTZ NOT NULL`
  - `open_price NUMERIC(18,6) NULL`
  - `high_price NUMERIC(18,6) NULL`
  - `low_price NUMERIC(18,6) NULL`
  - `close_price NUMERIC(18,6) NULL`
  - `volume BIGINT NULL`
  - `PRIMARY KEY (symbol, time_stamp)`
- rollup views or materialized views
  - `stock_tick_5min`
  - `stock_tick_15min`
  - `stock_tick_30min`
  - `stock_tick_1hour`
  - `stock_tick_1day`
  - `stock_tick_1week`
  - `stock_tick_1month`

Phase 1 uses PostgreSQL-safe tables and materialized views. If TimescaleDB is enabled later on Railway, the same public table and view names remain; only the storage engine and refresh strategy change.

**Alerts and notifications**
- `alerts`
  - `alert_id BIGSERIAL PRIMARY KEY`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `symbol TEXT NOT NULL`
  - `condition TEXT NOT NULL CHECK (condition IN ('ABOVE','BELOW','PERCENT_CHANGE'))`
  - `target NUMERIC(18,6) NOT NULL`
  - `is_active BOOLEAN NOT NULL DEFAULT TRUE`
  - `triggered BOOLEAN NOT NULL DEFAULT FALSE`
  - `cooldown_seconds INTEGER NOT NULL DEFAULT 0`
  - `last_triggered_at TIMESTAMPTZ NULL`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `notifications`
  - `notification_id BIGSERIAL PRIMARY KEY`
  - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
  - `alert_id BIGINT NULL REFERENCES alerts(alert_id)`
  - `title TEXT NOT NULL`
  - `body TEXT NOT NULL`
  - `is_read BOOLEAN NOT NULL DEFAULT FALSE`
  - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- additive support tables
  - `alert_trigger_events`
  - `notification_deliveries`
  - `outbox_events`
  - **`[Mobile_5_17_26]` `device_push_tokens`**
    - `device_id UUID PRIMARY KEY` (client-stable id)
    - `user_id BIGINT NOT NULL REFERENCES users(user_id)`
    - `fcm_token TEXT NOT NULL`
    - `platform TEXT NOT NULL CHECK (platform IN ('ios','android'))`
    - `app_version TEXT NULL`
    - `is_active BOOLEAN NOT NULL DEFAULT TRUE`
    - `last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
    - `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
    - `UNIQUE (user_id, fcm_token)`

**Screener and flags**
- `screener_strategies`
  - saved user-defined screen filters
- `feature_flags`
  - `flag_key TEXT PRIMARY KEY`
  - `is_enabled BOOLEAN NOT NULL DEFAULT FALSE`
  - `description TEXT NULL`
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`

#### Required feature flags
Preserve these keys:
- `use_microservice_auth`
- `use_microservice_portfolio`
- `use_microservice_market`
- `enable_live_trading`
- `enable_simulator`
- `enable_screener`

#### Indexing strategy
- `idx_users_email`
- `idx_otp_email`
- `idx_otp_expires`
- `idx_user_sessions_user`
- `idx_watchlist_user`
- `idx_watchlist_items_watchlist`
- `idx_positions_user`
- `idx_alerts_user`
- `idx_alerts_active`
- `idx_alerts_symbol_active`
- `idx_notifications_user`
- `idx_notifications_unread`
- `idx_outbox_events_status_next_attempt`
- **`[Mobile_5_17_26]`** `idx_device_push_tokens_user_active`

#### Data ownership
- `users`, `otp_tokens`, `user_sessions`: auth and identity source of truth
- `watchlists`, `watchlist_items`: watchlist module source of truth
- `portfolio_event`, `positions`, `portfolio_snapshot`: portfolio source of truth
- `stock_tick` and rollup views: market cache and history source of truth inside the monolith
- `alerts`, `alert_trigger_events`: alert definition and trigger source of truth
- `notifications`, `notification_deliveries`: user notification source of truth
- **`[Mobile_5_17_26]`** `device_push_tokens`: FCM registration source of truth per user/device
- `feature_flags`: runtime behavior control source of truth

#### Migration and rollback strategy
- all schema changes are additive first
- destructive changes wait until at least one release after deprecation
- production rollback prefers forward-fix over blind schema downgrade
- contract-breaking API changes require `/api/v2`
- additive field changes preserve existing JSON shape and nullability rules

### 1.6 Data Flow Diagram
#### 1. Login and OTP verification
1. Flutter calls `POST /api/v1/auth/send-otp` with normalized email.
2. Flask checks rate limits and lock status.
3. Flask creates or updates a `users` row and inserts an `otp_tokens` challenge.
4. Worker sends OTP through SendGrid, or console/Mailpit in local mock mode.
5. Flutter calls `POST /api/v1/auth/verify-otp`.
6. Flask validates challenge, expiry, attempt count, and OTP hash.
7. On success, Flask creates `user_sessions`, returns access/refresh tokens, and the client stores them.

#### 2. Dashboard load
1. Flutter loads `/dashboard`.
2. Backend returns dashboard aggregates from Postgres plus cached market snapshots.
3. Flutter renders the REST payload immediately.
4. Socket.IO connects to `/stream` and subscribes only to visible symbols.
5. Live quote updates patch the screen without replacing the canonical REST model.

#### 3. Watchlist read and symbol updates
1. Flutter requests `/api/v1/watchlist`.
2. Backend returns watchlists and symbol counts from `watchlists` and `watchlist_items`.
3. For detail pages, backend joins watchlist symbols with quote cache and returns current or stale prices.
4. Add/remove symbol mutations invalidate server cache and refresh the corresponding client provider.

#### 4. Alert evaluation and notification delivery
1. Streamer receives new Alpaca quotes.
2. Streamer writes current quote cache and publishes lightweight symbol events.
3. Alert evaluator checks active `alerts` for affected symbols.
4. When an alert crosses its threshold:
   - write `alert_trigger_events`
   - insert `notifications`
   - insert `outbox_events`
5. Worker processes the outbox:
   - push websocket notification
   - send email if enabled
   - **`[Mobile_5_17_26]`** send FCM push if user has active device token and channel includes `PUSH`
   - mark delivery status

#### 5. WebSocket reconnect
1. Client loses socket connection mid-session.
2. Client shows "Live prices reconnecting..." and retries with exponential backoff.
3. On reconnect, client re-authenticates, re-subscribes, and refetches REST snapshots.
4. Client clears the stale banner only after the REST snapshot confirms current state.

#### 6. Degraded-mode behavior
- **Redis down**
  - cache is bypassed
  - auth endpoints fail closed if rate-limit state cannot be trusted
  - read-heavy dashboard requests may get slower
  - websocket fan-out becomes degraded
- **SendGrid down**
  - `send-otp` returns a retriable error
  - challenge rows are not consumed until email send succeeds or timeout policy expires
- **Alpaca/Alpha Vantage down**
  - API returns stale cached values where safe
  - websocket may pause
  - dashboard and symbol pages display stale timestamps
- **Postgres unavailable**
  - app returns `503 SERVICE_UNAVAILABLE`
  - readiness endpoint fails

### 1.7 Key Technical Decisions and Why
| Decision | Choice | Why |
|---|---|---|
| application architecture | modular monolith | simplest deploy and operations model for MVP, while keeping clean module boundaries and an extraction path later |
| auth ownership | Flask-owned email OTP + JWT | avoids split runtime ownership between Flask, Supabase Auth, and a different primary database; keeps one API contract and one source of truth |
| primary database | Railway PostgreSQL | supports the whole MVP with simpler operations than multiple datastores |
| cache and async transport | Redis | enough for caching, queue transport, and lightweight pub-sub at MVP scale |
| realtime transport | Socket.IO namespace `/stream` | robust reconnect behavior on web and mobile; easy Flutter integration |
| client platforms | Flutter Web + iOS + Android `[Mobile_5_17_26]` | single codebase; native stores for primary MVP mobile delivery |
| push delivery | FCM + APNs via Firebase `[Mobile_5_17_26]` | reaches users when app is backgrounded or killed; complements in-app socket |
| mobile distribution | App Store + Play Store `[Mobile_5_17_26]` | standard trust and update channel for consumer finance-adjacent apps |
| realtime consistency model | REST authoritative, websocket incremental | prevents drift and makes reconnect/replay behavior predictable |
| market storage | `stock_tick` plus Postgres rollups first, optional Timescale later | safe phase-1 deployment on standard Railway Postgres while preserving future scale-up path |
| feature-flag strategy | `feature_flags` table | changes behavior without deployment and preserves later microservice cutover points |
| shared contract | single response envelope + exact field names | prevents frontend/backend mismatch such as `userId` versus `id` |
| portfolio semantics | `BUY/SELL` events are user-recorded transactions | fits the MVP without brokerage execution or KYC |
| external service strategy | ports/adapters + mock mode | local development should work before live Alpaca, Alpha Vantage, or SendGrid keys exist |
| reliability strategy | DB outbox for critical alerts and notifications | avoids losing critical user-visible events when Redis or workers misbehave |
| migration strategy | additive-first schema changes and `/api/v2` for breaking changes | safest way to evolve the MVP contract without breaking Flutter clients |

---

## 2. Implementation Plan

This plan is intentionally split into **backend-first** and **frontend-first** tasks so the project can be developed and committed in small, reviewable units without entangling UI and API work.

### Phase 1: MVP Foundation
Goal: establish the repo skeleton, local development environment, contract-safe auth flow, shared infrastructure, and test harness.

#### 1. Local infrastructure and repo skeleton
**Backend**
- create `backend/` application root
- add `docker-compose.yml` for PostgreSQL 16 and Redis 7
- add optional Mailpit profile for local email capture
- add `backend/.env.example`
- create `backend/requirements.txt`, `backend/wsgi.py`, `backend/worker.py`, `backend/scheduler.py`, `backend/streamer.py`

**Frontend**
- create `frontend/` Flutter app (**iOS + Android + optional Web**)
- add core dependencies: `flutter_riverpod`, `go_router`, `dio`, `socket_io_client`, `google_fonts`
- **`[Mobile_5_17_26]`** add `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `flutter_local_notifications`, `connectivity_plus`, `package_info_plus`
- **`[Mobile_5_17_26]`** run `flutter create .` platform folders if missing; configure `android/` (`compileSdk`/`targetSdk` 36) and `ios/` (deployment target, capabilities)
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
- frontend smoke test: app renders shell route in Chrome *(web)* and on Android emulator / iOS simulator **`[Mobile_5_17_26]`**
- CI smoke job: install dependencies and run the smallest boot test for both apps
- **`[Mobile_5_17_26]`** CI: `flutter analyze`, `flutter test`, `flutter build apk --debug` on Linux; `flutter build ios --no-codesign` on macOS runner

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

**[Mobile_5_17_26] Mobile CI/CD (add alongside Task 7)**

**File/module-level breakdown (mobile release)**
- `.github/workflows/mobile-release.yml` — tagged releases only
- `frontend/fastlane/` *(optional)* — Fastlane lanes for TestFlight + Play upload

**Mobile CI jobs**
| Job | Runner | Command / action |
|---|---|---|
| `mobile-analyze-test` | ubuntu-latest | `flutter analyze`, `flutter test` |
| `android-build` | ubuntu-latest | `flutter build appbundle --release` |
| `ios-build` | macos-latest | `flutter build ipa --release` with signing secrets |
| `android-submit` | manual | upload AAB to Play internal track |
| `ios-submit` | manual | upload IPA to TestFlight |

**Secrets (GitHub Actions)**
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
- `PLAY_SERVICE_ACCOUNT_JSON`
- `IOS_DIST_CERT_P12`, `IOS_PROVISION_PROFILE`, `APP_STORE_CONNECT_API_KEY`
- `FIREBASE_SERVICE_ACCOUNT_JSON` (backend worker FCM send)

**Estimated effort:** 3–5 days for first green mobile CI pipeline.

**File/module-level breakdown**
- `.github/workflows/ci.yml`
- **`.github/workflows/mobile-release.yml`** `[Mobile_5_17_26]`
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

#### Phase 1 summary dependencies
1 -> 2 -> 3 -> 4 -> 6  
1 -> 5 -> 6  
1..6 -> 7

#### Phase 1 main risks
- auth contract changes after frontend wiring begins
- Redis outages affecting auth rate limits if failure policy is unclear
- local setup friction if Docker is not the default path

### Phase 2: Core Features
Goal: build the core user value loop: dashboard, watchlists, charts, alerts, notifications, portfolio, and realtime updates.

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

#### Phase 2 summary dependencies
8 -> 9  
8 -> 10 -> 11  
8 + 9 + 11 -> 12  
8 + 12 -> 13  
8 + 9 -> 14 -> 15  
8 -> 16 -> 17

#### Phase 2 main risks
- external market-provider quotas
- websocket churn and stale-state handling
- cross-module contract drift between market, alerts, and dashboard

### Phase 3: Enhancements
Goal: add the screener, tighten feature flags and migration safety, and harden reliability, performance, accessibility, and observability for production.

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
- accessibility pass for focus order, semantics, contrast, keyboard navigation, and toasts
- add production-grade degraded-state copy

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

#### Phase 3 summary dependencies
18 -> 19  
3 -> 20  
1..20 -> 21 -> 22 -> 23

#### Phase 3 main risks
- screener scope creep
- compatibility mistakes during contract evolution
- late-stage performance work exposing earlier design shortcuts

### Phase 4: Mobile Platform (iOS + Android) `[Mobile_5_17_26]`

Goal: ship store-ready native clients with push, deep links, safe-area UI, and automated release builds. Can run **in parallel** with Phase 2 after Task 5 (shell) and Task 6 (auth) exist.

#### 24. Mobile app shell, safe areas, and bottom navigation
**Frontend**
- implement `mobile_shell.dart` with `BottomNavigationBar` / `NavigationBar`
- implement `safe_screen.dart` wrapping feature scaffolds in `SafeArea`
- adapt dashboard, watchlists, alerts, portfolio for single-column phone layout
- minimum 48dp touch targets on primary actions
- replace web-only `app_shell.dart` usage on `Platform.isAndroid || Platform.isIOS`

**Dependencies:** Task 5 routing shell

**Testing:** widget tests for tab selection; golden tests on iPhone 14 Pro simulator frame (notch)

**Effort:** 1–2 weeks

#### 25. Push notifications (FCM + APNs) — full stack
**Frontend**
- integrate `firebase_messaging` + `flutter_local_notifications`
- request `POST_NOTIFICATIONS` on Android 13+
- register token after login; `DELETE` on logout
- handle foreground, background, terminated + deep link navigation

**Backend**
- migration for `device_push_tokens`
- `POST /api/v1/devices/register`, `DELETE /api/v1/devices/:deviceId`
- worker: FCM HTTP v1 sender; prune invalid tokens on `UNREGISTERED`
- extend `notificationChannel` with `PUSH`; outbox handler dispatches push

**Dependencies:** Task 4 auth, Task 14 alerts/notifications

**Testing:** Firebase console test message; integration test for tap → `GoRouter` navigation

**Effort:** ~1 week engineering + 1–2 days Apple/Firebase console setup

#### 26. Deep linking (Universal Links + App Links)
**Frontend / platform**
- configure `AndroidManifest.xml` intent filters + hosted `assetlinks.json`
- configure iOS Associated Domains + hosted `apple-app-site-association`
- wire `go_router` initial location from `app_links` / `getInitialMessage` deep link

**Dependencies:** Task 5 routing

**Effort:** 2–4 days (includes DNS + HTTPS hosting for well-known files)

#### 27. App Store and Play Store submission
**Ops / frontend**
- store listings, screenshots, privacy policy, data safety forms
- TestFlight + Play internal testing → production rollout
- version discipline: `pubspec.yaml` `version: x.y.z+build` increment every upload

**Dependencies:** Tasks 24–26, Phase 2 feature-complete on device

**Effort:** 1–2 weeks calendar time (review queues dominate)

#### Phase 4 summary dependencies
5 -> 24  
4 + 14 -> 25  
5 -> 26  
24 + 25 + 26 + Phase2 -> 27

#### Phase 4 main risks
- APNs misconfiguration (silent iOS push failures)
- Play targetSdk policy changes — keep `targetSdk = 36` in CI
- store rejection for missing privacy policy or financial disclaimers
- background isolate bugs in FCM handler (no singletons in top-level handler)

### Rollout and commit strategy
- commit backend and frontend foundation separately
- commit each module backend first, then frontend
- do not merge a frontend feature until the backend fixture contract is frozen
- keep migration files in dedicated commits
- run contract tests before every feature merge

### Global blocker checklist
- live provider keys missing: use mock adapters and Mailpit/console email
- Redis unavailable locally: frontend work may continue against read-only mocked API, but backend auth tests must still run against Redis
- market provider quota exhaustion: use recorded fixtures for CI and development
- websocket instability in staging: keep REST fallback fully functional and treat live updates as enhancement, not correctness layer
- **`[Mobile_5_17_26]`** no Apple Developer / Play Console account: blocks TestFlight and production push on real devices
- **`[Mobile_5_17_26]`** missing macOS runner or signing certs: blocks `flutter build ipa` in CI
- **`[Mobile_5_17_26]`** Firebase project not linked: blocks FCM on both platforms

**[Mobile_5_17_26] Suggested delivery timeline (additive)**

| Step | What | Time |
|---|---|---|
| Android SDK 36 toolchain | Local + CI `compileSdk`/`targetSdk` 36 | ~1 day |
| Responsive UI + safe areas + bottom nav | Task 24 | 1–2 weeks |
| Push notifications | FCM + APNs + backend tokens (Task 25) | ~1 week |
| Deep linking | Manifest + entitlements + well-known files (Task 26) | 2–4 days |
| CI/CD mobile builds | APK/AAB + IPA pipelines | 3–5 days |
| App Store submission | Accounts, assets, review (Task 27) | 1–2 weeks |
| PWA (optional, not native substitute) | Service worker + manifest | 2–3 days if needed later |

---

## 3. README / Developer Guide

### 3.1 Project Overview
Alpha Cues is a production-ready MVP blueprint for a **stock market alert and notification app** (Web + **native iOS/Android** per `[Mobile_5_17_26]`). The product focuses on fast watchlist management, live price visibility, charts, strategy screening, manual portfolio tracking, and real-time alerts without introducing brokerage execution or KYC complexity in the first release.

The target architecture is a **modular monolith**:
- one Flutter client (Web optional; **iOS + Android primary** for mobile edition)
- one Flask backend
- one primary PostgreSQL database
- one Redis instance for caching, queues, and realtime fan-out

This repository now contains the planning baseline for building that MVP:
- `ARCHITECTURE.md`
- `IMPLEMENTATION_PLAN.md`
- `README.md`

### 3.2 Tech Stack
#### Frontend
- Flutter (Web optional + **iOS + Android** `[Mobile_5_17_26]`)
- Riverpod
- `go_router`
- `dio`
- Socket.IO client
- `google_fonts` with `Inter`
- charting library such as `fl_chart`
- **`[Mobile_5_17_26]`** `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `flutter_local_notifications`, `connectivity_plus`

#### Backend
- Flask
- SQLAlchemy
- Alembic
- Celery
- Flask-SocketIO
- Flask-Limiter
- Marshmallow or Pydantic for validation/serialization

#### Data and infrastructure
- PostgreSQL 16
- Redis 7
- Railway for backend, database, and worker deployment
- Vercel for Flutter Web deployment *(optional)*
- **`[Mobile_5_17_26]`** App Store Connect + Google Play Console for mobile distribution
- **`[Mobile_5_17_26]`** Firebase project for FCM (and optional Crashlytics)

#### External services
- Alpaca for real-time and market quote/history data
- Alpha Vantage for fundamentals and fallback metadata
- SendGrid for OTP email delivery

### 3.3 Setup Instructions
The recommended local workflow is **Docker-first** for infrastructure and **mock-first** for external providers.

#### 1. Prerequisites
- Docker Desktop
- Python 3.12+
- Flutter stable with **iOS and Android** toolchains enabled `[Mobile_5_17_26]`
- **Xcode 15+** (macOS) for iOS builds `[Mobile_5_17_26]`
- **Android Studio** with SDK Platform **36** and build-tools `[Mobile_5_17_26]`
- Node.js is optional unless frontend tooling later requires it
- **Apple Developer** + **Google Play Console** accounts for store release `[Mobile_5_17_26]`

#### 2. Start local infrastructure
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

#### 3. Backend setup
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

#### 4. Frontend setup
Expected target layout:

```text
frontend/
  lib/
  test/
  web/
```

Install packages and run the web app:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

**[Mobile_5_17_26] Run on Android / iOS (development)**

```bash
cd frontend
flutter pub get
flutter devices                    # list emulators and physical devices
flutter run -d <device_id>         # hot reload on emulator or USB device
flutter run --release -d <device_id>   # performance smoke before store build
```

**[Mobile_5_17_26] Production mobile builds**

```bash
cd frontend
flutter build appbundle --release   # upload to Play Console
flutter build apk --release         # QA sideload only
flutter build ipa --release         # macOS + signing; then TestFlight
```

Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase console; never commit production secrets to public repos — use CI secrets or local-only files in `.gitignore`.

### 3.4 Environment Variables (.env example)
The MVP should support both **real provider mode** and **local mock mode**.

#### Backend `.env.example`
```bash
APP_ENV=development
SECRET_KEY=replace-me
JWT_ISSUER=alphacues
JWT_AUDIENCE=alphacues-web
# [Mobile_5_17_26] also accept alphacues-mobile if separating clients
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

# [Mobile_5_17_26] FCM (backend worker) — path to service account JSON or base64 in CI
FCM_PROJECT_ID=
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-service-account.json
```

#### Frontend `.env` / config example
```bash
API_BASE_URL=http://localhost:5000/api/v1
SOCKET_BASE_URL=http://localhost:5000
USE_MOCK_API=false
APP_NAME=Alpha Cues
PRIMARY_COLOR=#7061F3
# [Mobile_5_17_26] deep link host for universal links
DEEP_LINK_HOST=app.alphacues.com
```

### 3.5 How to Run Locally
#### Fastest local path without live API keys
1. Start Docker services with `docker compose up -d`
2. Set backend `MOCK_EXTERNAL_SERVICES=true`
3. Set `EMAIL_BACKEND=console` or use Mailpit SMTP
4. Run backend API, worker, scheduler, and streamer locally
5. Run Flutter Web in Chrome
6. Use the local auth flow with console OTP or Mailpit-captured email

#### Local runtime expectations
- REST API base: `http://localhost:5000/api/v1`
- Socket.IO namespace: `/stream`
- Flutter app base: usually `http://localhost:3000` or the default Flutter web port
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- Mailpit UI: `http://localhost:8025`

#### Recommended test commands
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

### 3.6 Basic Usage Flow
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
11. **`[Mobile_5_17_26]`** On mobile, user grants notification permission; app registers FCM token with backend.
12. **`[Mobile_5_17_26]`** When an alert triggers, user receives push (background/killed), in-app socket update (foreground), and email if enabled.
13. **`[Mobile_5_17_26]`** Tapping a push opens the correct screen via deep link (e.g. symbol or alerts).

### 3.7 Mock and Stub Strategy
Local development should not depend on live Alpaca, Alpha Vantage, or SendGrid keys.

#### Backend adapter strategy
- `EmailSender`
  - production: SendGrid
  - local: console sender or Mailpit SMTP
- `MarketDataSource`
  - production: Alpaca + Alpha Vantage
  - local/CI: fixture-backed fake provider

#### Frontend strategy
- preferred mode: connect the real local Flask API with mocked external services behind it
- optional mode: set `USE_MOCK_API=true` for pure UI work before backend endpoints exist

### 3.8 Contracts and Compatibility Rules
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

### 3.9 Edge Cases and Degraded Behavior
#### OTP
- expires after 5 minutes
- 5 wrong attempts lock the challenge context for 15 minutes
- resend is rate-limited
- wrong OTP responses stay generic enough to reduce account enumeration

#### Session
- access token expiry should trigger a single refresh attempt
- refresh failure logs the user out and redirects to `/login`

#### WebSocket
- disconnect mid-session shows a reconnect banner
- reconnect triggers re-subscribe plus REST refresh
- auth failure on reconnect should stop infinite retry loops

#### Redis
- if cache is unavailable, read paths degrade to direct database or provider fetches where safe
- auth rate-limit paths should fail closed
- websocket fan-out may degrade, but REST remains the correctness layer

#### Empty-state UX
- no watchlists: show create-watchlist CTA
- no holdings: show add-holdings CTA
- no alerts: show create-alert CTA
- no screener matches: show "No matches" state, not a blank table

### 3.10 Recommended Reading Order
1. `ARCHITECTURE.md`
2. `IMPLEMENTATION_PLAN.md`
3. `README.md`

### 3.11 Current Repository Status
This repository currently documents the MVP blueprint and implementation plan. The next engineering step is to scaffold `backend/` and `frontend/` following `IMPLEMENTATION_PLAN.md`.

---

## 4. Appendix: docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: alphacues-postgres
    environment:
      POSTGRES_USER: alphacues
      POSTGRES_PASSWORD: alphacues
      POSTGRES_DB: alphacues
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U alphacues -d alphacues"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  redis:
    image: redis:7-alpine
    container_name: alphacues-redis
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s

  mailpit:
    image: axllent/mailpit:latest
    container_name: alphacues-mailpit
    profiles:
      - mail
    ports:
      - "1025:1025"
      - "8025:8025"
    healthcheck:
      test: ["CMD-SHELL", "wget --spider -q http://127.0.0.1:8025 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

volumes:
  pgdata:
  redisdata:
```

---

## 5. Mobile Conversion Appendix `[Mobile_5_17_26]`

This section answers: how complete was the original web-only plan for mobile, what you listed, what else production mobile needs, and recommended priorities. The original blueprint body (Sections 1–4) is preserved above; this appendix is the mobile delta index.

### 5.1 How right were you? (1–10)

**Score: 8.5 / 10**

You identified the highest-impact gaps between a Flutter **Web** MVP plan and a **store-shipped mobile** product. The original final plan already said "mobile-first" in design language, but it assumed **Vercel + browser storage + in-app/email only** — so your list correctly targets real delivery blockers.

**What you got right**
- App Store / Play Store pipeline (absent in original)
- Push beyond in-app + email (FCM + APNs)
- Deep linking (web URLs ≠ native universal links)
- Android SDK 36 / Play target API policy
- Safe areas, bottom nav, touch targets
- `flutter build apk` / `flutter build ipa` (and App Bundle for Play)

**Small corrections**
- **Play production** should prefer **`flutter build appbundle`** over APK for store upload.
- **API 36** is the **2026** Play target for new apps; **2025** policy emphasized **API 35** (Android 15). Plan both: ship MVP on 35+ if timeline is 2025, move to **36** before 2026 store deadlines.
- **PWA** is optional and largely orthogonal to native store apps — do not count it as required for "mobile conversion" unless you explicitly want installable web.

### 5.2 What was missing from the original final plan (checklist)

| # | Gap | In mobile plan? |
|---|---|---|
| 1 | App Store / Play deployment pipeline | Yes — §1.1, Phase 4 Task 27, §5.3 |
| 2 | FCM + APNs push | Yes — API, DB, Phase 4 Task 25 |
| 3 | Deep linking (manifest + entitlements + well-known) | Yes — §1.2, Task 26 |
| 4 | Android SDK 36 / toolchain | Yes — §1.2 |
| 5 | Safe areas + native navigation | Yes — §1.2, Task 24 |
| 6 | Mobile CI (`apk`/`aab`/`ipa`) | Yes — Task 7 mobile CI |
| 7 | Secure token storage (not browser) | Yes — `flutter_secure_storage` |
| 8 | App lifecycle / background socket behavior | Partial — see §5.4 |
| 9 | Store legal: privacy policy, disclaimers, data safety | Yes — Task 27 |
| 10 | Physical device + release-mode testing | Yes — §1.2 testing |
| 11 | Firebase project + platform config files | Yes — §3.3 |
| 12 | Android 13+ notification permission | Yes — §1.2 |
| 13 | Push tap → cold start routing | Yes — deep link + `getInitialMessage` |
| 14 | Backend device token table + FCM sender | Yes — `device_push_tokens` |
| 15 | Obfuscation + split debug symbols for release | Yes — build commands |
| 16 | App icon + splash native assets | Yes — packages listed |
| 17 | Flavors (dev/staging/prod API URLs) | See §5.4 |
| 18 | Offline / airplane mode UX | See §5.4 |
| 19 | Certificate pinning (finance app hardening) | See §5.4 (post-MVP) |
| 20 | Accessibility on mobile (VoiceOver/TalkBack) | Extends Phase 3 Task 23 |

### 5.3 Recommended specific changes (your table + plan mapping)

| Step | What | Time | Plan reference |
|---|---|---|---|
| PWA support | Service worker + manifest (optional) | 2–3 days | Out of scope for native; §1.2 PWA note |
| Responsive UI fixes | Safe areas, bottom nav, touch targets | 1–2 weeks | Task 24 |
| Push notifications | FCM + APNs + backend tokens | ~1 week | Task 25 |
| App Store submission | Accounts, screenshots, review | 1–2 weeks | Task 27 |
| Android SDK 36 fix | Toolchain + `targetSdk` | ~1 day | §1.2 Android SDK |
| CI/CD mobile builds | AAB + IPA pipelines | 3–5 days | Task 7 mobile CI |

### 5.4 Additional mobile items (research-backed, not in your list)

**[Mobile_5_17_26] Should add for a finance-adjacent alert app**

1. **App lifecycle and Socket.IO** — On background, OS may suspend the socket; on resume, run the same reconnect + REST refresh path as web. Do not assume perpetual background websocket on mobile.
2. **Build flavors** — `dev` / `staging` / `prod` with different `API_BASE_URL` (Flutter `--dart-define` or `flutter_flavorizr`); separate Firebase projects per env recommended.
3. **App Tracking Transparency (iOS)** — Only if you add cross-app tracking ads; analytics SDKs may need ATT prompt.
4. **Privacy nutrition labels** — App Store Privacy Details + Google Data safety form must match actual data collected (email, device token, usage).
5. **Non-advisory disclaimer** — Store description and in-app copy: alerts are informational, not investment advice (reduces review risk).
6. **Rate limiting on device register** — Prevent token spam on `/devices/register`.
7. **FCM token hygiene** — Worker deletes tokens on `UNREGISTERED` / `INVALID_ARGUMENT`; update `last_seen_at` on app open.
8. **Local notification channel IDs (Android)** — High-importance channel for price alerts.
9. **iOS Notification Service Extension** — Optional for rich notifications (image/logo); skip for MVP.
10. **Tablet layouts** — Defer unless iPad/Android tablet is in scope; use phone layout first.
11. **In-app update prompts** — Optional `upgrader` package when `minSupportedVersion` API is added later.
12. **Screenshot / golden tests** — `golden_toolkit` for critical screens before store screenshots.
13. **Network security** — `android:usesCleartextTraffic="false"`; iOS ATS; no HTTP in production.
14. **Secrets** — Never embed Alpaca/SendGrid keys in the app; only JWT + public API base URL.
15. **Crash and performance** — `sentry_flutter` or Firebase Crashlytics + Firebase Performance for release builds.

### 5.5 Code examples quick reference `[Mobile_5_17_26]`

**Bottom navigation shell (sketch):**
```dart
// mobile_shell.dart — [Mobile_5_17_26]
Scaffold(
  body: SafeArea(child: child),
  bottomNavigationBar: NavigationBar(
  selectedIndex: currentIndex,
  onDestinationSelected: (i) => goBranch(i),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.star), label: 'Watchlists'),
    NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
    NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Portfolio'),
  ],
),
);
```

**Register FCM token after login (sketch):**
```dart
// [Mobile_5_17_26]
final token = await FirebaseMessaging.instance.getToken();
await api.post('/devices/register', data: {
  'fcmToken': token,
  'platform': Platform.isIOS ? 'ios' : 'android',
  'deviceId': await deviceIdProvider.future,
  'appVersion': packageInfo.version,
});
```

**Backend outbox push branch (sketch):**
```python
# worker — [Mobile_5_17_26]
if channel includes PUSH:
    tokens = DevicePushTokenService.active_tokens_for(user_id)
    fcm.send_multicast(tokens, title=..., data={"deepLink": f"/symbols/{symbol}"})
```

### 5.6 Document change log

| Tag | Meaning |
|---|---|
| `Mobile_5_17_26` | Added or updated for web → native iOS/Android conversion on 2026-05-17 |

Search the repository copy of this file: `grep -n 'Mobile_5_17_26' plan.final_mobile.md`

**Original file preserved:** `alphacues_mvp_design_86b7618e_final.plan.md` (not modified).
