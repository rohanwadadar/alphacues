---
name: AlphaCues MVP Design v1
overview: "v1 of the AlphaCues MVP plan: same deliverables (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, README.md) plus a complete implementation spec — local Docker, mocks/fakes, API JSON contracts, edge cases, Flutter routing and Riverpod hierarchy, per-task tests, API/DB migration strategy, and UI state specs. Tagging convention for v1 deltas vs the original plan file alphacues_mvp_design_86b7618e.plan.md: #5_12_26_add_v1, #5_12_26_update_v1, #5_12_26_delete_v1 (commented-out originals only; do not erase history)."
todos:
  - id: architecture-md
    content: Write ARCHITECTURE.md (include v1 sections — mocks, contracts, edge cases, routing, providers)
    status: pending
  - id: implementation-plan-md
    content: Write IMPLEMENTATION_PLAN.md (split tasks, docker-compose, per-task tests, migration/versioning)
    status: pending
  - id: readme-md
    content: Write README.md (docker-first local setup, mock modes, troubleshooting matrix)
    status: pending
  - id: docker-compose
    content: Add docker-compose.yml (Postgres + Redis; optional Mailpit for email capture in dev)
    status: pending
isProject: false
---

# AlphaCues MVP — Full-Stack Architecture and Implementation Plan (v1)

This file is **v1** of the plan. It **extends** [alphacues_mvp_design_86b7618e.plan.md](alphacues_mvp_design_86b7618e.plan.md) with a **complete implementation specification**. When generating repo docs, merge v1 sections into `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, and `README.md` as appropriate.

**Delta tags** (traceability for reviewers and agents):

- `#5_12_26_add_v1` — new requirement or section.
- `#5_12_26_update_v1` — revised guidance (original kept nearby as a comment where required).
- `#5_12_26_delete_v1` — superseded text preserved only as HTML/Markdown comment (do not delete history).

---

## v1 preamble — Research and standards baked in #5_12_26_add_v1

The v1 spec aligns with common production practice:

- **OTP / abuse**: OWASP-style throttling, lockout, and generic error messages to reduce user enumeration (combine with rate limits already in the base plan).
- **HTTP APIs**: A single **envelope** for every JSON response so Flutter and Flask never disagree on top-level keys (`data` vs `user` vs raw objects).
- **Resilience**: Redis down → degrade gracefully (no cache, no pub-sub fan-out) with explicit HTTP status and UI copy; do not fail the whole app if non-critical paths break.
- **Local dev**: **Docker Compose** for Postgres + Redis so day-one setup is one command; **fakes** for SendGrid / Alpaca / Alpha Vantage / Supabase JWT verification in `TESTING` and optional `DEVELOPMENT` modes.
- **Flutter Web**: `go_router` paths declared once; **Riverpod** scopes: global `ProviderScope`, core `Notifier`/`AsyncNotifier` for session, feature-scoped providers for repositories.
- **Contract testing**: Golden JSON fixtures checked in CI (backend schema dump vs Flutter `fromJson`).

---

## 1. ARCHITECTURE.md (base + v1 additions)

### 1.1 System Overview

*(Same as v0; unchanged.)*

AlphaCues is a **modular monolith** — a single deployable Flask application with strict module boundaries, one PostgreSQL database (tables namespaced per module), and Redis for caching, queues, and pub-sub. The frontend is Flutter Web (Vercel CDN). Real-time market data streams from Alpaca into workers; alerts fan out via Redis and Flask-SocketIO.

```mermaid
graph TD
    subgraph frontend [Frontend - Vercel CDN]
        FlutterWeb["Flutter Web App"]
    end

    subgraph backend [Backend - Railway]
        Flask["Flask App (Gunicorn + Gevent)"]
        Celery["Celery Workers"]
        SocketIO["Flask-SocketIO"]
    end

    subgraph data [Data Layer - Railway]
        Postgres["PostgreSQL"]
        Redis["Redis"]
    end

    subgraph external [External Services]
        Alpaca["Alpaca Markets API"]
        AlphaVantage["Alpha Vantage API"]
        Supabase["Supabase Auth"]
        SendGrid["SendGrid Email"]
    end

    FlutterWeb -->|"REST API + WebSocket"| Flask
    Flask --> Postgres
    Flask --> Redis
    Celery --> Redis
    Celery --> Postgres
    Flask --> SocketIO
    SocketIO -->|"Real-time push"| FlutterWeb
    Alpaca -->|"WebSocket stream"| Celery
    AlphaVantage -->|"REST (fundamentals)"| Celery
    Flask --> Supabase
    Celery --> SendGrid
```



**Scale target**: 3,000–5,000 concurrent users (same rationale as v0: gevent workers, Redis cache, Celery, CDN).

### 1.2 Frontend Structure (Flutter Web)

*(Base structure unchanged; v1 adds routing + provider hierarchy + UI states — see §1.8–1.10.)*

### 1.3 Backend Structure (Flask Modular Monolith)

*(Base structure unchanged; v1 adds `adapters/` fakes — see §1.11.)*

**Add to tree** #5_12_26_add_v1: `app/adapters/` — `email.py`, `market_data.py`, `identity.py`, `protocols.py` (typing.Protocol or ABCs); production and `fake_*.py` implementations selected by `MOCK_EXTERNAL_SERVICES` / `EMAIL_BACKEND`.

### 1.4 API Design (Endpoints)

All endpoints under `**/api/v1/`** (version in URL). Auth required unless noted.

**Auth** (`/api/v1/auth`): `POST /register`, `POST /login`, `POST /verify-otp`, `POST /refresh`, `GET /me`, `PUT /me`, `POST /logout`

**Watchlist** (`/api/v1/watchlist`): CRUD + symbols

**Portfolio** (`/api/v1/portfolio`): summary, holdings, performance

**Alerts** (`/api/v1/alerts`): CRUD, history, notifications

**Screener** (`/api/v1/screener`): scan, presets, indicators

**Market** (`/api/v1/market`): quote(s), history, fundamentals, search, WebSocket stream

### 1.4.1 Global JSON envelope and error model #5_12_26_add_v1

**Rule**: Every HTTP JSON response uses the same top-level shape. **WebSocket** events use the same `payload` object shapes as REST `data` where applicable.

**Success (2xx)**:

```json
{
  "success": true,
  "data": {},
  "meta": {
    "requestId": "uuid",
    "apiVersion": "1"
  }
}
```

**Error (4xx/5xx)** — machine codes for Flutter switches; human `message` for UI:

```json
{
  "success": false,
  "error": {
    "code": "OTP_EXPIRED",
    "message": "This code expired. Request a new one.",
    "details": {}
  },
  "meta": {
    "requestId": "uuid",
    "apiVersion": "1"
  }
}
```

**HTTP status mapping (examples)**:


| Condition                    | HTTP         | `error.code`                                        |                |
| ---------------------------- | ------------ | --------------------------------------------------- | -------------- |
| Validation failed            | 422          | `VALIDATION_ERROR`                                  |                |
| Wrong OTP                    | 401          | `OTP_INVALID`                                       |                |
| OTP expired                  | 401          | `OTP_EXPIRED`                                       |                |
| OTP attempts exceeded        | 429          | `OTP_LOCKED`                                        |                |
|                              | Rate limited | 429                                                 | `RATE_LIMITED` |
| Auth missing/invalid JWT     | 401          | `UNAUTHORIZED`                                      |                |
| Feature disabled by flag     | 403          | `FEATURE_DISABLED`                                  |                |
| Redis unavailable (degraded) | 200 or 503   | `DEGRADED_CACHE` / `SERVICE_UNAVAILABLE` (see §1.9) |                |
| Upstream market data timeout | 504          | `UPSTREAM_TIMEOUT`                                  |                |


**Example — `POST /api/v1/auth/login` success**:

```json
{
  "success": true,
  "data": {
    "otpChallengeId": "550e8400-e29b-41d4-a716-446655440000",
    "emailMasked": "u***@example.com",
    "expiresInSeconds": 300
  },
  "meta": { "requestId": "…", "apiVersion": "1" }
}
```

**Example — `POST /api/v1/auth/verify-otp` success**:

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt…",
    "refreshToken": "jwt…",
    "expiresInSeconds": 900,
    "user": {
      "userId": "uuid",
      "email": "user@example.com",
      "displayName": "Alex"
    }
  },
  "meta": { "requestId": "…", "apiVersion": "1" }
}
```

**Example — `GET /api/v1/watchlist` success (list)**:

```json
{
  "success": true,
  "data": {
    "watchlists": [
      {
        "watchlistId": "uuid",
        "name": "Tech",
        "itemCount": 3,
        "updatedAt": "2026-05-12T12:00:00Z"
      }
    ]
  },
  "meta": { "requestId": "…", "apiVersion": "1", "cursor": null }
}
```

**Example — `GET /api/v1/market/quote/AAPL` success**:

```json
{
  "success": true,
  "data": {
    "symbol": "AAPL",
    "last": 189.12,
    "changePercent": 0.42,
    "currency": "USD",
    "asOf": "2026-05-12T16:00:00Z",
    "source": "alpaca"
  },
  "meta": { "requestId": "…", "apiVersion": "1" }
}
```

**Naming contract**: Flutter DTOs **must** use identical keys (`userId`, `watchlistId`, …). Add **contract tests** that parse fixture JSON (see Implementation Plan per-task tests).

### 1.4.2 WebSocket / Socket.IO event contract #5_12_26_add_v1

**Transport**: Socket.IO (engine.io) on same origin as API or explicit `wss://api…` with CORS configured.

**Client → server** (subscribe after connect; `auth` carries JWT in handshake or first `emit`):

```json
{
  "type": "subscribe_quotes",
  "requestId": "uuid",
  "payload": { "symbols": ["AAPL", "MSFT"] }
}
```

**Server → client** (every outbound event wraps payload the same way as REST `data` keys):

```json
{
  "type": "quote_update",
  "payload": {
    "symbol": "AAPL",
    "last": 189.12,
    "changePercent": 0.42,
    "asOf": "2026-05-12T16:00:01Z"
  },
  "meta": { "apiVersion": "1" }
}
```

```json
{
  "type": "notification_new",
  "payload": {
    "notificationId": "uuid",
    "title": "AAPL crossed $190",
    "body": "Your price alert fired.",
    "alertId": "uuid",
    "createdAt": "2026-05-12T16:00:02Z"
  },
  "meta": { "apiVersion": "1" }
}
```

**Server → client errors** (do not disconnect silently):

```json
{
  "type": "error",
  "payload": { "code": "UNAUTHORIZED", "message": "Invalid or expired token." },
  "meta": { "apiVersion": "1" }
}
```

**Example — `GET /api/v1/alerts` success**:

```json
{
  "success": true,
  "data": {
    "alerts": [
      {
        "alertId": "uuid",
        "symbol": "AAPL",
        "alertType": "PRICE_ABOVE",
        "targetValue": 190.0,
        "isActive": true,
        "isTriggered": false,
        "createdAt": "2026-05-12T10:00:00Z"
      }
    ]
  },
  "meta": { "requestId": "…", "apiVersion": "1" }
}
```

**Example — `GET /api/v1/alerts/notifications` success (paginated)**:

```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "notificationId": "uuid",
        "title": "Alert triggered",
        "body": "TSLA fell below $200",
        "isRead": false,
        "createdAt": "2026-05-12T15:59:00Z",
        "alertId": "uuid"
      }
    ]
  },
  "meta": { "requestId": "…", "apiVersion": "1", "nextCursor": "opaque-string-or-null" }
}
```

**Example — `GET /api/v1/portfolio` success**:

```json
{
  "success": true,
  "data": {
    "portfolioId": "uuid",
    "holdingsValue": 12500.5,
    "costBasis": 12000.0,
    "plAmount": 500.5,
    "plPercent": 4.17,
    "asOf": "2026-05-12T16:00:00Z",
    "quoteStale": false
  },
  "meta": { "requestId": "…", "apiVersion": "1" }
}
```

**Pagination rule** #5_12_26_add_v1: list endpoints return a module-specific array under `data` **and** `meta.nextCursor` (opaque string or `null`). Do not put the cursor only inside `data` unless legacy; new code uses `meta` only.

### 1.5 Database Design

*(Same ER model as v0.)*

### 1.6 Data Flow Diagram

*(Same as v0.)*

### 1.7 Key Technical Decisions

*(Same table as v0.)*

### 1.8 Flutter routing map (go_router) #5_12_26_add_v1

**Principles**: Public routes without auth; shell routes with **redirect** if no valid session; deep links preserve path after login.


| Path                       | Screen / feature                                   | Auth                 |
| -------------------------- | -------------------------------------------------- | -------------------- |
| `/`                        | Redirect → `/dashboard` if logged in else `/login` | —                    |
| `/login`                   | Email capture + “Send code”                        | Public               |
| `/verify-otp`              | OTP entry (query: `challengeId` or pass via extra) | Public               |
| `/dashboard`               | Home dashboard                                     | Private              |
| `/watchlists`              | List of watchlists                                 | Private              |
| `/watchlists/new`          | Create watchlist                                   | Private              |
| `/watchlists/:watchlistId` | Watchlist detail + symbols                         | Private              |
| `/symbols/:symbol`         | Stock detail (chart, quote, fundamentals)          | Private              |
| `/alerts`                  | Alerts list                                        | Private              |
| `/alerts/new`              | Create alert                                       | Private              |
| `/portfolio`               | Portfolio summary + holdings                       | Private              |
| `/screener`                | Screener                                           | Private (flag-gated) |
| `*`                        | Not found → `/dashboard` or dedicated `/not-found` | —                    |


**Web note**: Flutter Web uses path-based URLs (`usePathUrlStrategy()`). Document base href for Vercel.

### 1.9 Edge cases and degraded behavior (normative) #5_12_26_add_v1

**OTP**


| Scenario                                     | Server behavior                             | HTTP | `error.code`              | UI                                                |
| -------------------------------------------- | ------------------------------------------- | ---- | ------------------------- | ------------------------------------------------- |
| OTP never requested / wrong `otpChallengeId` | Reject                                      | 404  | `OTP_CHALLENGE_NOT_FOUND` | “Start over from email.”                          |
| Wrong OTP (1–4 failures)                     | Increment `failedAttempts`, generic message | 401  | `OTP_INVALID`             | “Code doesn’t match. N tries left.”               |
| Wrong OTP (5th failure within window)        | Lock **email + IP** for 15 minutes          | 429  | `OTP_LOCKED`              | “Too many tries. Wait 15 min or contact support.” |
| OTP expired (>5 min)                         | Mark challenge expired; reject              | 401  | `OTP_EXPIRED`             | “Code expired. Resend.”                           |
| Resend spam                                  | Rate limit 5/min/IP + 3/15min/email         | 429  | `RATE_LIMITED`            | Show countdown                                    |


**JWT / session**


| Scenario             | Server                                                                                                | Client                                                                               |
| -------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Access token expired | 401 `TOKEN_EXPIRED`                                                                                   | Interceptor: single-flight `POST /refresh`; on success retry once; on failure logout |
| Refresh invalid      | 401                                                                                                   | Clear storage; navigate `/login`                                                     |
| Logout               | Invalidate refresh server-side if using denylist (optional MVP: client-only clear + short access TTL) | Invalidate all `AsyncNotifier`s via `ref.invalidate` / auth `Notifier` state         |


**WebSocket**


| Scenario                     | Behavior                                                                                     |
| ---------------------------- | -------------------------------------------------------------------------------------------- |
| Disconnect mid-session       | Exponential backoff reconnect (1s, 2s, 4s… max 30s); show banner “Live prices reconnecting…” |
| Reconnect after long idle    | Re-subscribe symbols; refetch REST snapshot for drift                                        |
| Auth failure on connect      | Do not infinite loop; show “Session expired” → login                                         |
| Server deploy / idle timeout | Same as disconnect                                                                           |


**Redis unavailable**


| Subsystem                  | Behavior                                                                                                                                                                                      |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cache read/write           | Skip cache; slower path OK; log warning                                                                                                                                                       |
| Rate limiter               | Fail-open OR fail-closed (pick **fail-closed** for auth endpoints, **fail-open** for read-only quotes if product accepts risk — document choice; default **fail-closed** for `/auth/*`)       |
| Celery broker              | Queue operations fail; return 503 for actions that **require** queue (e.g. “send OTP” if email only via queue) — **MVP mitigation**: sync fallback send in dev/mock only; prod requires Redis |
| Pub-sub / SocketIO adapter | SocketIO without Redis adapter = single process only; health check should report `degraded`                                                                                                   |


**Postgres**


| Scenario                  | Behavior                                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------------------ |
| Connection pool exhausted | 503 `SERVICE_UNAVAILABLE`; retry-after header                                                    |
| Migration pending         | Health `/health` returns `503` + `migrations_pending: true`; block deploy in CI if migrate fails |


### 1.10 Riverpod provider hierarchy and lifecycle #5_12_26_add_v1

**Top level**: `ProviderScope` in `main.dart` with overrides in tests (`ProviderContainer`).

**Layered providers (recommended names)**:

1. `**coreProvider`** — env (`AppConfig`), base URL, `USE_MOCK_API`.
2. `**storageProvider**` — secure / shared preferences.
3. `**apiClientProvider**` — `Dio` + interceptors; reads `authSessionProvider` for access token.
4. `**authSessionProvider**` — `AuthSessionNotifier extends AsyncNotifier<AuthSession?>`:
  - State: `null` (logged out), `AuthSession(access, refresh, user)`.
  - Methods: `sendOtp`, `verifyOtp`, `refreshTokens`, `logout`.
  - On successful `verifyOtp`: persist tokens → set state → `ref.invalidate` on **user-scoped** providers (watchlists, alerts, portfolio).
  - On `refresh` failure: `logout()` clears tokens and invalidates children.
5. `**routerProvider`** — `GoRouter` with `refreshListenable` **not** required if using `redirect` that reads `authSessionProvider` via `ref.read` in `GoRouter` constructor closure (Flutter 3.16+: use `Listenable` bridge `GoRouterRefreshStream` from auth notifier).
6. **Feature repos** — `watchlistRepositoryProvider`, `marketRepositoryProvider`, etc., each `Provider` returning repository impl (HTTP or mock).
7. **UI models** — `watchlistsProvider` = `FutureProvider` / `AsyncNotifierProvider` depending on mutation needs.

**Token refresh**: Dio interceptor on 401: if request is not `/auth/refresh`, pause queue, await `authSessionNotifier.refreshTokens()`, replay once. Use a **Completer lock** to avoid parallel refresh storms.

**Logout propagation**: `AuthSessionNotifier.logout()` → clear secure storage → set state `null` → `ref.invalidate(watchlistRepositoryProvider)` (and all feature providers) → `router.go('/login')`.

### 1.11 Mock / stub / fake strategy (local + CI) #5_12_26_add_v1

**Environment flags** (add to `.env.example` and `AppConfig`):

```bash
# Backend
MOCK_EXTERNAL_SERVICES=false   # true = no real SendGrid/Alpaca/AV/Supabase network calls
EMAIL_BACKEND=sendgrid         # console | sendgrid | smtp (smtp = Mailpit in docker)
SUPABASE_JWT_VERIFY=remote     # remote | local (local = verify HS256 with dev secret only in test)

# Frontend
API_BASE_URL=http://localhost:5000
USE_MOCK_API=false             # true = in-memory repositories for UI work without backend
```

**Adapters (ports and adapters)** in backend `app/adapters/`:


| Port                   | Production                      | Mock / Dev                                                                                              |
| ---------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `EmailSender`          | SendGrid API                    | `ConsoleEmailSender` logs OTP to stdout; **Mailpit** SMTP captures HTML in UI (`http://localhost:8025`) |
| `MarketDataSource`     | Alpaca + Alpha Vantage          | `FakeMarketDataSource` returns static JSON from `tests/fixtures/market/`                                |
| `AuthIdentityProvider` | Supabase Admin API + JWT verify | `FakeAuthIdentityProvider` issues dev JWT with known secret (tests only)                                |
| `OtpHasher`            | bcrypt / argon2 of OTP          | Plain noop in test with fixed code `000000` gated by `TESTING=true` only                                |


**Day 1 workflow without API keys**: `docker compose up -d` → `MOCK_EXTERNAL_SERVICES=true` → run Flask → OTP visible in **console** or **Mailpit** → Flutter hits real local API → full auth flow testable.

**CI**: GitHub Actions uses `MOCK_EXTERNAL_SERVICES=true`, `pytest`, no secrets; contract tests read committed JSON fixtures.

### 1.12 UI states — loading, empty, error, offline #5_12_26_add_v1

**Global**: Use `AsyncValue` from Riverpod; never leave a blank screen — always one of skeleton / error / empty / data.


| Screen           | Loading           | Empty                                 | Error                               | Offline / degraded                                           |
| ---------------- | ----------------- | ------------------------------------- | ----------------------------------- | ------------------------------------------------------------ |
| Dashboard        | Skeleton cards    | “Add your first watchlist” CTA purple | Retry banner + `error.code`         | Banner: “Showing last fetched prices”; show cached timestamp |
| Watchlists       | List skeleton     | Illustration + “Create watchlist”     | Same                                | Disable add if no cache                                      |
| Watchlist detail | Row skeletons     | “No symbols yet” + search             | Symbol add validation errors inline | Stale badge on prices                                        |
| Stock / chart    | Chart placeholder | N/A for symbol route (404 if invalid) | “Market data unavailable”           | Static last candle + label                                   |
| Alerts           | Skeleton          | “No alerts yet” + CTA                 | Per-row error                       | Show paused if WS down                                       |
| Portfolio        | Skeleton          | “No holdings” + add CTA               | Same                                | P/L uses last known quote + stale tag                        |
| Notifications    | Skeleton          | “You’re all caught up”                | Toast + retry                       | —                                                            |


**Accessibility**: loading = `CircularProgressIndicator` with `SemanticsLabel`; errors = focus move to `SnackBar` / alert role.

---

## 2. IMPLEMENTATION_PLAN.md (base + v1 task updates)

### Phase 1: MVP Foundation (Weeks 1–2)

**Goal**: Flask boots with Postgres + Redis via Docker; auth works **without** live SendGrid/Supabase keys in dev; Flutter shell + routing + session.

**Task 0 — Docker Compose for local data stores** #5_12_26_add_v1

- Add `[docker-compose.yml](docker-compose.yml)` at repo root:
  - **Postgres 16**: port `5432`, user/password/db `alphacues`, volume `pgdata`.
  - **Redis 7**: port `6379`.
  - **Mailpit** (optional profile `mail`): SMTP `1025`, UI `8025` — set `EMAIL_BACKEND=smtp` + SMTP URL in `.env.example`.
- Add `Makefile` or scripts: `make up`, `make down`, `make logs`.
- **Tests**: CI job starts compose services as **service containers** OR uses ephemeral Postgres (either is fine; document one).

**Dependencies**: none (first task).

**Risks**: Apple Silicon / ARM image tags — use official multi-arch images.

---

**Task 1 — Project scaffolding — Backend** (same as v0 + below) #5_12_26_update_v1

- Add `app/adapters/` package and `MOCK_EXTERNAL_SERVICES` wiring in factory.
- **Tests**: health endpoint returns 200 with compose up.

**Task 2 — Database setup** (same as v0) #5_12_26_add_v1

- **Tests**: migration apply on clean DB; downgrade smoke optional.

**Task 3 — Shared infrastructure** (same as v0 + envelope) #5_12_26_update_v1

- Implement `**json_response(success, data=None, error=None)`** helper enforcing §1.4.1.
- **Tests**: unknown exception → 500 + `INTERNAL_ERROR` without leaking stack to client.

**Task 4 — Auth module — Backend** (same as v0 + mocks) #5_12_26_update_v1

- Implement `**ConsoleEmailSender`** and `**SendGridEmailSender**` behind `EmailSender` interface.
- OTP table fields: `failed_attempts`, `locked_until` (nullable), `challenge_id` (UUID).
- **Tests (required)**:
  - Unit: OTP generate, hash compare, expiry boundary.
  - Unit: 5 wrong attempts → lock.
  - Integration: `POST /login` + `verify` with `MOCK_EXTERNAL_SERVICES=true` reads OTP from fake sink.
  - Contract: login + verify success JSON matches fixture files.

**Task 5 — Project scaffolding — Frontend** (same as v0 + routing shell) #5_12_26_update_v1

- Add `go_router` with routes from §1.8 (stub screens).
- **Tests**: router redirect unauthenticated `/dashboard` → `/login`.

**Task 6 — Auth module — Frontend** (same as v0 + detail) #5_12_26_update_v1

- Implement `AuthSessionNotifier` per §1.10.
- **Tests**: `ProviderContainer` tests for token refresh lock; widget test for OTP error states.

**Task 7 — CI/CD** (same as v0) #5_12_26_add_v1

- CI must run **with** Docker Compose services or service containers; no skipped tests for “no Redis”.

---

### Phase 2: Core Features (Weeks 3–5)

**Task 8 — Market data — Backend** #5_12_26_update_v1

- `MarketDataSource` interface + `FakeMarketDataSource` for dev.
- **Tests**: quote endpoint returns fixture shape; cache hit/miss unit tests (mock Redis or fakeredis).

**Task 9 — WebSocket infrastructure** #5_12_26_update_v1

- **Tests**: client connect with JWT; disconnect reconnect logic unit-tested on client with fake socket (or integration test with short timeout).



**Task 10a — Watchlist module — Backend only** #5_12_26_add_v1

- Models, migrations, service, routes, Marshmallow schemas aligned with §1.4.1.
- **Tests**: CRUD integration; duplicate symbol returns 409 `DUPLICATE_SYMBOL`; pagination if added.

**Task 10b — Watchlist module — Frontend only** #5_12_26_add_v1

- Screens: `/watchlists`, `/watchlists/:id`; empty/loading/error states per §1.12.
- **Tests**: widget tests for empty list; golden test optional.

**Dependencies**: 10b after 10a (API stable).

**Task 11 — Dashboard — Frontend** #5_12_26_update_v1

- **Tests**: skeleton snapshot or smoke widget test.

**Task 12 — Charts — Frontend** #5_12_26_update_v1

- **Tests**: chart widget renders with mock OHLC list (no network).

**Task 13 — Alerts — Backend** #5_12_26_update_v1

- **Tests**: evaluation unit tests with frozen clock and fake price feed; idempotency: same tick does not double-notify.

**Task 14 — Alerts — Frontend** #5_12_26_update_v1

- **Tests**: create form validation; WS notification inserts into list (mock channel).



**Task 15a — Portfolio — Backend only** #5_12_26_add_v1

- **Tests**: P/L math unit tests with known quotes; holding validation (qty > 0).

**Task 15b — Portfolio — Frontend only** #5_12_26_add_v1

- **Tests**: empty holdings CTA; edit dialog validation.

**Risks**: Same as v0 (Alpaca WS limits, AV rate limits).

---

### Phase 3: Enhancements (Weeks 6–7)



**Task 16a — Screener — Backend** #5_12_26_add_v1

- **Tests**: filter validation; deterministic scan on fixture universe.

**Task 16b — Screener — Frontend** #5_12_26_add_v1

- **Tests**: results table with zero rows empty state.

**Task 17 — Feature flags admin** (same as v0) #5_12_26_add_v1

- **Tests**: when flag off, endpoint returns 403 `FEATURE_DISABLED`.

**Task 18 — Testing and quality** #5_12_26_update_v1

- Expand: contract suite covers **all** modules; minimum coverage threshold (e.g. 80% on `services.py` per module) — tune in CI.

**Tasks 19–21** — unchanged from v0; cross-reference §1.9 for security/rate limits.

---

### Per-task minimum test matrix (summary) #5_12_26_add_v1


| Task            | Unit            | Integration    | Contract / E2E       |
| --------------- | --------------- | -------------- | -------------------- |
| 0 Docker        | —               | compose health | CI service up        |
| 1 scaffold      | config load     | `/health`      | —                    |
| 2 DB            | —               | migrate        | —                    |
| 3 shared        | envelope helper | error handler  | JSON fixture         |
| 4 auth          | OTP rules       | login/verify   | auth fixtures        |
| 5 FE scaffold   | —               | —              | router               |
| 6 FE auth       | notifier        | —              | widget OTP           |
| 7 CI            | —               | full pytest    | Flutter test         |
| 8 market        | cache           | quote route    | market fixture       |
| 9 WS            | client backoff  | connect        | optional integration |
| 10a/b watchlist | service         | CRUD API       | list fixture         |
| 11 dashboard    | —               | —              | widget smoke         |
| 12 charts       | data mapping    | —              | golden optional      |
| 13 alerts       | evaluator       | API            | alert fixture        |
| 14 alerts FE    | —               | —              | widget               |
| 15a/b portfolio | P/L             | API            | holding fixture      |
| 16a/b screener  | rules           | scan           | scan fixture         |
| 17 flags        | cache ttl       | admin API      | —                    |
| 18+             | coverage        | locust         | —                    |


---

### API and database migration / versioning strategy #5_12_26_add_v1

**URL versioning**: Breaking HTTP changes → `/api/v2/`; v1 remains until Flutter minimum version sunset.

**Additive DB changes**: Always **additive** migrations in MVP (new nullable columns, new tables). Avoid destructive drops until one release after deprecation.

**Response versioning**: `meta.apiVersion` always `"1"`. If field deprecated, keep field + add new field for one release; document in `CHANGELOG.md`.

**Alert model example**: If Phase 2 adds `alerts.cooldown_seconds`, default `0` in migration so Phase 1 rows remain valid. Rollback: down migration restores previous schema only if safe; production rollback plan = **forward-fix** preferred (new migration to revert behavior).

**Contract drift guard**: CI step: `python tools/export_openapi.py` (optional) or static `schemas.json` committed; Flutter codegen or manual DTO tests must pass.

---

## 3. README.md (base + v1)

### Content outline additions #5_12_26_add_v1

- **Docker-first**: `docker compose up -d` then run Flask / Celery / Flutter with `DATABASE_URL` and `REDIS_URL` pointing at compose ports.
- **Mock mode**: table of env vars and what they disable.
- **Troubleshooting**: Redis down, OTP lock, WebSocket reconnect.

### Example `docker-compose.yml` (spec — implement in Task 0) #5_12_26_add_v1

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: alphacues
      POSTGRES_PASSWORD: alphacues
      POSTGRES_DB: alphacues
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
  mailpit:
    profiles: ["mail"]
    image: axllent/mailpit
    ports: ["1025:1025", "8025:8025"]
volumes:
  pgdata: {}
```

### `.env.example` additions #5_12_26_add_v1

```bash
MOCK_EXTERNAL_SERVICES=false
EMAIL_BACKEND=console
# When using docker compose mail profile:
# EMAIL_BACKEND=smtp
# SMTP_URL=smtp://localhost:1025

DATABASE_URL=postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues
REDIS_URL=redis://localhost:6379/0
```

---

## Document deliverable checklist (for the engineer)

When creating the three repo docs from this plan, ensure each includes:

- Docker Compose + Mailpit path documented #5_12_26_add_v1
- Mock / fake adapters and env flags #5_12_26_add_v1
- Global JSON envelope + examples #5_12_26_add_v1
- Edge-case matrix (OTP, WS, Redis, DB) #5_12_26_add_v1
- Flutter routes table #5_12_26_add_v1
- Riverpod hierarchy + refresh + logout #5_12_26_add_v1
- Split backend/frontend tasks for watchlist, portfolio, screener #5_12_26_add_v1
- Per-task tests #5_12_26_add_v1
- API/DB migration strategy #5_12_26_add_v1
- UI empty/loading/error/offline specs #5_12_26_add_v1

---

*End of v1 plan. Original numbered content from v0 is preserved above where not commented; v1 is the source of truth for implementation order and specs.*