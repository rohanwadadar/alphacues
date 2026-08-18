# Alpha Cues MVP - Systematic Task Tracker (`track.md`)

> **Project Root**: `c:\Users\Admin\Desktop\ALPHA`  
> **Last Updated**: 2026-07-28 22:19 UTC  

---

## 📌 Master Phase & Task Status Overview

| Phase | Description | Task # | Task Name | Component | Status | Notes / Changes Made |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | Foundation | Tasks 1-6 | Repo Skeleton, Shared Infra, Auth, DB Schema | Backend & Frontend | `COMPLETED` | Initial skeleton, JWT auth, db migrations, shared envelope |
| **Phase 2** | Core Features | Tasks 7-17 | Market Data, Watchlist, Portfolio, Alerts | Backend & Frontend | `COMPLETED` | Market adapters, watchlist CRUD, portfolio events, alerts worker |
| **Phase 3** | Enhancements | Task 18 | Screener Backend | Backend | `COMPLETED` | Implemented strategy CRUD, deterministic scan, contract fixtures, migration |
| **Phase 3** | Enhancements | Task 19 | Screener UI | Frontend | `COMPLETED` | Flutter Screener UI — full 5-state screen, repository, providers, widgets, 3 test files |
| **Phase 3** | Enhancements | Task 20 | Feature Flags & Compatibility | Backend | `COMPLETED` | Admin flag endpoints, Redis cache + invalidation, require_admin stub (deny-by-default, TODO marked), 3 integration tests |
| **Phase 3** | Enhancements | Task 21 | Contract Versioning & Migration Safety | Backend | `COMPLETED` | Modular contract fixtures, deprecation policy doc, contract_check script, CHANGELOG.md, additive migration test |
| **Phase 3** | Enhancements | Task 22 | Performance & Reliability Hardening | Backend & Frontend | `COMPLETED` | Audited strategy indexes, slow request timing logging, quote fanout coalescing, outbox retries + dead-letter metrics, Riverpod scoping audit, 3 performance test files |
| **Phase 4** | Mobile Platform | Task 24 | Mobile App Shell, Safe Areas, Bottom Nav | Frontend | `COMPLETED` | `mobile_shell.dart`, `safe_screen.dart`, single-column phone layout, 48dp touch targets, 3 test files |
| **Phase 4** | Mobile Platform | Task 25 | Push Notifications (FCM + APNs) | Backend & Frontend | `COMPLETED` | `device_push_tokens` DB migration, `/api/v1/devices/register` & `/api/v1/devices/:id`, FCM outbox worker, 3 integration tests |
| **Phase 4** | Mobile Platform | Task 26 | Deep Linking | Frontend & Platform | `COMPLETED` | Intent filters, `assetlinks.json`, `apple-app-site-association`, `go_router` cold-start routing |
| **Phase 4** | Mobile Platform | Task 27 | App Store and Play Store Submission | Ops & Release | `COMPLETED` | Versioning `x.y.z+build`, SDK 36 target compliance, privacy policy, legal forms |
| **Phase 4** | Mobile Platform | Task 28 | Build Flavors (Dev / Staging / Prod) | Frontend | `COMPLETED` | Environment isolation via `--dart-define`, API & socket base URL bindings |
| **Phase 4** | Mobile Platform | Task 29 | Offline and Connectivity UX | Frontend | `COMPLETED` | `connectivity_plus` listener, persistent offline banner, cached REST data timestamp, chaos reconnect test |




---

## 🛠️ Phase-Wise & Task-Wise Change Logs

### 🔵 Phase 3 — Task 18: Screener Backend
**Status**: `COMPLETED`  
**Files Modified / Created**:
1. 📄 **SQLAlchemy Model**: `backend/app/modules/screener/models.py`
   - Confirmed & verified `ScreenerStrategy` model matching `screener_strategies` table schema.
   - Column fields: `strategy_id` (PK, BigInteger), `user_id` (FK to `users`), `name`, `description`, `filters` (JSONB), `sort_by`, `sort_order`, `created_at`, `updated_at`.
2. 📄 **Alembic Migration**: `backend/migrations/versions/f0a1b2c3d4e5_add_screener_strategies_table.py` [NEW]
   - Added database migration creating `screener_strategies` table with index `idx_screener_strategies_user`.
   - Down revision: `e9f6a4b13c5d`.
3. 📄 **Schemas**: `backend/app/modules/screener/schemas.py`
   - Enforced closed enum lists for `VALID_SORT_FIELDS` (`marketCap`, `peRatio`, `price`, `changePercent`, `symbol`) and `VALID_SORT_ORDERS` (`asc`, `desc`).
   - Range validation (`marketCapMin` <= `marketCapMax`, `peRatioMin` <= `peRatioMax`, etc.) raising 422 `ValidationError`.
4. 📄 **Service Layer**: `backend/app/modules/screener/service.py`
   - Added deterministic screening logic via `run_scan()` consuming `MarketDataSource` interface.
   - Tied scan sorting with tuple tie-breaker on `symbol` for deterministic order-stable results.
   - Added paginated user strategy retrieval `get_user_strategies_paginated()` returning `(items, next_cursor)`.
5. 📄 **Routes**: `backend/app/modules/screener/routes.py`
   - Implemented canonical endpoints:
     - `POST /api/v1/screener/run` (and alias `/scan`) -> execute deterministic screen
     - `GET /api/v1/screener/strategies` -> list user strategies with `meta.nextCursor` pagination (limit default 20, max 100)
     - `POST /api/v1/screener/strategies` -> create saved strategy (HTTP 201)
     - `GET /api/v1/screener/strategies/:id` -> get strategy details
     - `PUT /api/v1/screener/strategies/:id` -> update strategy details
     - `DELETE /api/v1/screener/strategies/:id` -> delete strategy (HTTP 204)
     - `POST /api/v1/screener/strategies/:id/run` -> run saved strategy
   - Wrapped endpoints with `@require_auth` and `@require_feature_flag("enable_screener")`.
6. 📄 **Tests**: `backend/app/modules/screener/tests/test_screener.py`
   - Unit tests for filter validation & enum rejection (HTTP 422).
   - Deterministic scan test asserting identical results on repeated calls.
   - Full CRUD lifecycle test for saved strategies.
   - Contract fixture verification test for `screener_results.json`, `screener_strategy.json`, `screener_strategy_list.json`.

---

## 🔵 Phase 3 — Task 19: Screener Frontend
**Status**: `COMPLETED`  
**Files Modified / Created**:
1. 📄 **Repository**: `frontend/lib/features/screener/data/screener_repository.dart` [MODIFIED]
   - Fixed endpoint: `POST /api/v1/screener/run` (was incorrectly `/api/v1/screener/scan`).
   - Added `ScreenerStrategyListResult` return type with `nextCursor` from `meta.nextCursor`.
   - Defined `screenerRepositoryProvider` (exact name from plan's provider hierarchy).
   - Routes through existing `dioProvider` → `apiClientProvider` (no second HTTP client).
2. 📄 **Models**: `frontend/lib/features/screener/data/screener_models.dart` [MODIFIED]
   - Added `ScreenerStrategyListResult` class for cursor-paginated strategy list.
   - Filter fields match closed enum from backend `ScreenerFilterSchema`: `marketCapMin/Max`, `peRatioMin/Max`, `priceMin/Max`, `changePercentMin/Max`, `dividendYieldMin`, `exchange`.
   - Sort fields match `VALID_SORT_FIELDS`: `marketCap | peRatio | price | changePercent | symbol`.
3. 📄 **Providers**: `frontend/lib/features/screener/data/screener_providers.dart` [MODIFIED]
   - `ScreenerState` with all 5 states: loading, empty, error (filters preserved), offline/degraded, feature-disabled.
   - `ScreenerNotifier` reads `AppConfig.instance.enableScreener` for flag-gated path.
   - `SavedStrategiesNotifier` owns `AsyncValue<List<ScreenerStrategy>>` with save/delete mutations.
4. 📄 **Screen**: `frontend/lib/features/screener/presentation/screener_screen.dart` [MODIFIED]
   - Complete 5-state screen matching plan's state table for Screener row.
5. 📄 **Widget**: `frontend/lib/features/screener/presentation/widgets/screener_loading_skeleton.dart` [NEW]
   - Filter placeholder + table skeleton for Loading state.
6. 📄 **Widget**: `frontend/lib/features/screener/presentation/widgets/screener_result_card.dart` [NEW]
   - Single result row card (symbol, exchange, price, change%, marketCap, P/E, dividend).
7. 📄 **Widget**: `frontend/lib/features/screener/presentation/widgets/saved_strategies_bar.dart` [NEW]
   - Horizontal chip list; tap to apply, long-press to delete.
8. 📄 **Test**: `frontend/test/features/screener/screener_empty_state_test.dart` [NEW]
   - Widget test: "No matches" after zero-result run; confirms not blank.
9. 📄 **Test**: `frontend/test/features/screener/screener_feature_disabled_test.dart` [NEW]
   - Widget test: disabled state when `enable_screener=false`; nav index 4 not returned.
10. 📄 **Test**: `frontend/test/features/screener/screener_strategy_provider_test.dart` [NEW]
    - Provider test: save strategy → appears in list; delete → removed (6 tests, all passing).

**Routing**: Already wired in `app_router.dart` (no changes needed) — `/screener` hidden when `enable_screener=false`, redirects to `/dashboard`; optional 5th tab in `authenticated_shell.dart`.

**Flag mechanism**: `AppConfig.instance.enableScreener` (reads `ENABLE_SCREENER` dart-define) — same path used by router and nav shell. No second flag-fetching path introduced.

**Verification**: `flutter analyze` — No issues. `flutter test test/features/screener/` — 6/6 passed.

---

## 🔵 Phase 3 — Task 20: Feature-flag Admin and Compatibility Controls
**Status**: `COMPLETED`  
**Files Modified / Created**:
1. 📄 **Admin Package Init**: `backend/app/modules/admin/__init__.py` [NEW]
2. 📄 **Admin Service**: `backend/app/modules/admin/service.py` [NEW]
   - `AdminFlagService.list_flags()` — returns all feature flags ordered by key.
   - `AdminFlagService.get_flag(flag_key)` — single flag or `NotFoundError`.
   - `AdminFlagService.update_flag(flag_key, is_enabled)` — toggles flag, commits, then calls `invalidate_flag_cache()` immediately.
   - `AdminFlagService.flag_to_dict(flag)` — serializes to `{flagKey, isEnabled, description, updatedAt}`.
3. 📄 **Admin Routes**: `backend/app/modules/admin/routes.py` [NEW]
   - `GET /api/v1/admin/flags` — list all flags (admin only).
   - `GET /api/v1/admin/flags/<flag_key>` — single flag (admin only).
   - `PATCH /api/v1/admin/flags/<flag_key>` — toggle `is_enabled` with body validation (admin only).
   - All routes guarded by `@require_admin`.
4. 📄 **Feature Flags** (extended): `backend/app/shared/feature_flags.py` [MODIFIED]
   - Added `FLAG_CACHE_TTL_SECONDS = 5` constant.
   - Added `invalidate_flag_cache(flag_key)` — deletes `ff:<flag_key>` from Redis; safe when Redis is down.
   - `FeatureFlagService.is_enabled()` now checks Redis cache first (5s TTL), falls through to Postgres on miss, bypasses cache entirely in TESTING/MOCK mode.
   - All existing public API symbols (`require_feature_flag`, `FeatureFlag`, `feature_flag_service`, `REQUIRED_FEATURE_FLAGS`) unchanged.
5. 📄 **Auth Guard Stub**: `backend/app/shared/auth.py` [MODIFIED]
   - Added `require_admin` decorator at the end of the file.
   - **Deny-by-default**: raises `UnauthorizedError` until a real mechanism is wired in.
   - Contains a `# TODO(admin-auth)` block with all three implementation options: (A) `users.role` column in JWT, (B) `ADMIN_EMAILS` env-var list, (C) `X-Admin-Secret` service header.
6. 📄 **App Factory**: `backend/app/__init__.py` [MODIFIED]
   - Imports and registers `admin_bp` after `screener_bp`.
7. 📄 **Integration Tests**: `backend/tests/integration/test_feature_flags.py` [NEW]
   - Test 1: `test_disabled_screener_returns_403` — seeds `enable_screener=False`, hits `POST /api/v1/screener/run`, asserts HTTP 403 + `error.code == "FEATURE_DISABLED"` and full envelope shape.
   - Test 2: `test_flag_flip_reflects_without_deploy` — verifies pre-flip is 403, calls `PATCH /api/v1/admin/flags/enable_screener {is_enabled: true}`, then re-hits screener and asserts HTTP 200 (cache-invalidation proof).
   - Test 3: `test_admin_list_flags_returns_required_flags` — asserts all six required keys appear in `GET /api/v1/admin/flags`.
   - `require_admin` is monkeypatched to a no-op in each test (intentional; isolated from the unresolved admin-auth decision).

**No legacy aliases added**: No `/api/*` (non-v1) routes exist anywhere in the codebase, so no aliases are needed per plan backward-compatibility rules.

**Admin auth decision pending**: `require_admin` is a deny-by-default stub. Choose Option A/B/C in `auth.py` before shipping to production.

**Env/settings changes**: None required for this task. Env var only needed when admin-auth mechanism is chosen.

---

## 🔵 Phase 3 — Task 21: Contract Versioning and Migration Safety
**Status**: `COMPLETED`  
**Files Modified / Created**:
1. 📄 **Modular Contract Fixtures**: `backend/tests/fixtures/contracts/*` [NEW / ORGANIZED]
   - Organized fixtures per module (`admin/`, `alerts/`, `market/`, `notifications/`, `portfolio/`, `screener/`, `user/`, `watchlist/`).
2. 📄 **Deprecation & Versioning Policy**: `backend/docs/api_compatibility.md` [NEW]
   - Documented `/api/v1` base path canonical rule, `/api/v2` requirement for breaking changes, legacy alias rules, 1-cycle deprecation window, additive-first database migration guidelines, and engineer migration safety checklist.
3. 📄 **Contract Verification Script**: `backend/scripts/contract_check.py` [NEW]
   - Python CLI script validating canonical response envelopes (`success`, `data`, `error`, `meta`), field data types, and nullabilities across committed JSON fixtures. Exits code 0 on success, code 1 on failure for CI integration.
4. 📄 **Changelog**: `CHANGELOG.md` [NEW]
   - Initialized contract changelog tracking all Phase 1-3 endpoint releases and contract shapes module by module.
5. 📄 **Test Suite Update**: `backend/tests/test_contracts.py` [MODIFIED]
   - Updated fixture loader to support modular directory resolution and added `test_contract_fixtures_pass_contract_check()` wrapper.
6. 📄 **Additive Migration Test**: `backend/tests/integration/test_alert_contract_migration.py` [NEW]
   - Added test suite confirming additive nullable/optional field changes on `alerts` module are accepted as backward-compatible while type mismatches or key deletions trigger structural contract errors.

---

## 🔵 Phase 3 — Task 22: Performance and Reliability Hardening
**Status**: `COMPLETED`  
**Files Modified / Created**:
1. 📄 **Index Verification**: `backend/migrations/versions/*` [AUDITED]
   - Audited and verified all 14 strategy indexes (`idx_users_email`, `idx_otp_email`, `idx_otp_expires`, `idx_user_sessions_user`, `idx_watchlist_user`, `idx_watchlist_items_watchlist`, `idx_positions_user`, `idx_alerts_user`, `idx_alerts_active`, `idx_alerts_symbol_active`, `idx_notifications_user`, `idx_notifications_unread`, `idx_outbox_events_status_next_attempt`, `idx_device_push_tokens_user_active`) are present in Alembic migrations.
2. 📄 **Request Timing & Slow Endpoint Logging**: `backend/app/shared/logging.py` [MODIFIED]
   - Extended request correlation middleware (`register_request_correlation`) with `g.start_time` timing and `SLOW_ENDPOINT` warning logs for requests exceeding `200ms`.
3. 📄 **Cache Degradation & Monitoring**: `backend/app/shared/cache.py` [MODIFIED]
   - Added metrics counters (`_cache_hits`, `_cache_misses`, `_cache_bypasses`, `_stale_cache_hits`) and exposed `get_stale_cache_metrics()` to monitor Redis fallback states.
4. 📄 **Socket Fan-Out Micro-Batching**: `backend/app/shared/websocket.py` [MODIFIED]
   - Added `QuoteBatcher` coalescing buffer and `flush_quote_batch()` helper to prevent socket buffer congestion during high tick rates over `/stream`.
5. 📄 **Outbox Retries & Dead-Letter Visibility**: `backend/app/modules/notifications/service.py` [MODIFIED]
   - Implemented exponential backoff retry policy (`max_attempts = 3`, 5s backoff base) and transition to `"dead_letter"` state. Added `get_dead_letter_events()` and `get_outbox_metrics()` for queue depth and lag visibility.
6. 📄 **Backend Performance Tests**:
   - `backend/tests/performance/test_load_dashboard_watchlist.py` [NEW] — Dashboard and Watchlist endpoint load test asserting sub-200ms latency under batched load.
   - `backend/tests/performance/test_quote_fanout_stress.py` [NEW] — Stress test for quote fanout and tick coalescing.
7. 📄 **Frontend Reconnect Chaos Test**:
   - `frontend/test/performance/reconnect_chaos_test.dart` [NEW] — Socket reconnect chaos test verifying state machine, resubscribe triggers, and REST refresh snapshot completion before clearing stale connection banners.

---



## 🎯 Verification & Contract Check

- **Canonical Envelope**:
  ```json
  {
    "success": true,
    "data": {},
    "error": null,
    "meta": { "requestId": "uuid", "apiVersion": "1", "nextCursor": null }
  }
  ```
- **Error Codes**:
  - Validation Error -> `422 VALIDATION_ERROR`
  - Resource Not Found -> `404 NOT_FOUND`
  - Feature Flag Disabled -> `403 FEATURE_DISABLED`
  - Rate Limited -> `429 RATE_LIMITED`
