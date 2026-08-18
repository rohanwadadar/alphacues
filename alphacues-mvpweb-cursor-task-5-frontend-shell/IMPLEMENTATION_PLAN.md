# Alpha Cues — Frontend Implementation Plan (alphacues-mvpweb)

> **Canonical full plan:** [alphacues-mvpapi/IMPLEMENTATION_PLAN.md](https://github.com/AlphaCues-org/alphacues-mvpapi/blob/main/IMPLEMENTATION_PLAN.md)  
> Task numbers match **alphacues-mvpapi** for coordination.

**Backend in alphacues-mvpapi (not this repo):** 2, 3, 4, 8, 10, 14, 16, 18, 20, 21 (+ backend parts of 7, 22, 25).

---

## Phase 1: Foundation

### 1. Flutter skeleton
- Flutter project (iOS + Android; Web optional)
- `flutter_riverpod`, `go_router`, `dio`, `socket_io_client`, `google_fonts`
- Mobile: `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `flutter_local_notifications`, **`connectivity_plus`**, **`package_info_plus`**, **`cached_network_image`**, **`sentry_flutter`** (or Firebase Crashlytics)
- Android `compileSdk` / `targetSdk` 36; iOS 15.0+
- `.gitignore` for Firebase plist/json when added

**Depends on:** nothing

### 5. App shell and routing
- Theme, `go_router`, guards, loading/empty/error widgets, `app_config.dart`

**Depends on:** Task 1

### 6. Auth flow
- Login + OTP screens, `flutter_secure_storage`, single-flight refresh, logout invalidation
- **After successful `verifyOtp` on mobile:** call `POST /api/v1/devices/register` with current FCM token when push enabled (full wiring Task 25; no-op stub OK until backend exists)
- **`onTokenRefresh`:** listen from Task 25 setup; on new FCM token while logged in, call `POST /api/v1/devices/register` again (same payload as login) so backend always has the active token
- **On logout:** call `DELETE /api/v1/devices/:deviceId`, delete local FCM registration state, and cancel `onTokenRefresh` listener (client-side token clear; backend row removed in mvpapi)

**Depends on:** mvpapi Task 4 + Task 5

### 7. CI *(frontend)*
- `flutter analyze`, `flutter test`, format on PR
- Contract tests: `test/contracts/*` synced from mvpapi
- `mobile-release.yml`: `appbundle` + `ipa`
- **Build flavor matrix** (`--dart-define`):
  - `dev` → `http://localhost:5000/api/v1`
  - `staging` → staging API URL
  - `prod` → production API URL
- CI: analyze/test every PR; release job builds dev (debug APK), staging, prod (AAB + IPA) with matching defines

**Depends on:** Tasks 1, 5, 6

### 28. Build flavors *(dev / staging / prod)*
- `flutter_flavorizr` or `--dart-define` for `API_BASE_URL` / `SOCKET_BASE_URL`
- Separate Firebase projects per env (recommended)
- Document run/build commands in README

**Depends on:** Task 1 | **Effort:** 1–2 days

---

## Phase 2: Core features

### 9. Realtime
- Socket client, subscriptions, reconnect banner
- Re-subscribe + REST refresh after reconnect or **app resume from background**

**Depends on:** mvpapi Tasks 8–9

### 11. Watchlist UI — **Depends on:** mvpapi 10 + Task 9

### 12. Dashboard + symbol detail — **Depends on:** 8–11

### 13. Charts — **Depends on:** bars API + Task 12

### 15. Alerts + notifications UI — **Depends on:** mvpapi 14 + Task 9

### 17. Portfolio UI — **Depends on:** mvpapi 16 + Task 9

### 29. Offline and connectivity UX
- `connectivity_plus` global offline banner
- Cached data + stale timestamps; disable unsafe mutations offline
- On reconnect: socket + REST refresh (same as Task 9)

**Depends on:** Tasks 5, 9 | **Effort:** 2–4 days

**Rule:** No screen merge until mvpapi contract fixture exists for that module.

---

## Phase 3: Enhancements

### 19. Screener UI — **Depends on:** mvpapi 18 + `enable_screener`

### 22. Performance
- Debounce search, list virtualization, fewer rebuilds
- **`cached_network_image`** for symbol logos and `avatarUrl`

### 23. Accessibility + observability
- Semantics on icon-only buttons; labels on price-change indicators
- **TalkBack / VoiceOver:** reading order matches visual order on dashboard, watchlist rows, alert list; announce alert toasts
- Contrast **4.5:1** minimum; test font scale **1.3×**
- **`sentry_flutter` or Firebase Crashlytics** + optional Performance in release builds

---

## Phase 4: Mobile platform

### 24. Bottom nav + safe areas
- `mobile_shell.dart`, `SafeArea`, 48dp targets | **1–2 weeks**

### 25. Push *(frontend)*
- `firebase_messaging` + `flutter_local_notifications`
- Android 13+ (API 33): request runtime **`POST_NOTIFICATIONS`** before showing any notification UI
- **Register FCM token:** immediately after login (Task 6) and again on every **`FirebaseMessaging.onTokenRefresh`** while session is active → `POST /api/v1/devices/register`
- **Logout (client):** `DELETE /api/v1/devices/:deviceId`; clear cached token; unsubscribe refresh listener (pairs with Task 6 logout path)
- **Android notification channel:** create on app start (before first notification), e.g. id `price_alerts`, name “Price alerts”, **importance high**, sound + vibration enabled for alert triggers
- **All three FCM delivery states:**
  - **Foreground:** `FirebaseMessaging.onMessage` → local notification or in-app banner
  - **Background:** `onBackgroundMessage` (top-level function, `@pragma('vm:entry-point')`)
  - **Terminated:** `getInitialMessage` on cold start → `GoRouter.go(deepLink)`; tray resume via `onMessageOpenedApp`
- **Backend (mvpapi):** `device_push_tokens`, `/devices/register`, `/devices/:deviceId` DELETE, FCM worker, token hygiene on `UNREGISTERED`

**Depends on:** mvpapi 4 + 14 + Task 6 | **~1 week**

### 26. Deep linking
- `AndroidManifest.xml` intent filters
- iOS Associated Domains in `Runner.entitlements`
- Host on **production domain only** (e.g. `https://app.alphacues.com` — not localhost):
  - **`/.well-known/assetlinks.json`** (Android App Links verification)
  - **`/.well-known/apple-app-site-association`** (iOS Universal Links)
- `assetlinks.json` / AASA must list correct package name + signing cert SHA-256 (Android) and team ID + bundle ID (iOS)
- Cold start: `getInitialMessage` → `go_router`

**Depends on:** Task 5 | **2–4 days**

### 27. Store submission + release hardening
- TestFlight + Play internal / closed testing → production rollout
- Store assets: icons, screenshots (6.7" / 6.5" iPhone + Android phone), privacy policy **URL**
- **App Store Privacy Details** + **Google Play Data safety** form — must match real data collected (email, FCM token, usage)
- **Non-advisory disclaimer** in store description and in-app About/Legal: alerts are informational, not investment advice
- **Release obfuscation** (folded here):  
  `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android`  
  `flutter build ipa --release --obfuscate --split-debug-info=build/debug-info/ios`
- `pubspec.yaml` `version: x.y.z+build` increment every upload

**Depends on:** Tasks 24–26 + Phase 2 complete on device | **1–2 weeks** calendar

### 30. Physical device smoke test (pre-submission)
- Run **`flutter run --release`** on at least one **physical iPhone** (notch/Dynamic Island) and one **physical Android** device (API 33+ for notification permission)
- Verify: login/OTP, bottom nav, live quotes reconnect after backgrounding, push receive + tap → deep link, offline banner (Task 29)
- Capture screenshot set from these devices for Task 27 store listing

**Depends on:** Tasks 24–26, 29 | **Effort:** 1–2 days before Task 27 submit

---

## Dependency sketch

```text
1 → 5 → 6 → 7
1 → 28
5 + 9 → 29
mvpapi(8,9) → 9 → 11 → 12 → 13
mvpapi(14) → 15
mvpapi(16) → 17
5 → 24 → 30 → 27
mvpapi(4,14) + 6 → 25 → 30 → 27
5 → 26 → 30 → 27
24 + 29 → 30
```

---

## Blockers

- API down → `USE_MOCK_API` or mvpapi mock mode
- Fixture drift → pull latest from mvpapi `backend/tests/fixtures/contracts/`
- No Firebase → defer push; socket + in-app still work
- No signing certs → local `flutter run` only

---

## Rollout

- One feature branch per module; PR requires `flutter analyze` + `flutter test`
- `pubspec.yaml` `version: x.y.z+build` every store upload
