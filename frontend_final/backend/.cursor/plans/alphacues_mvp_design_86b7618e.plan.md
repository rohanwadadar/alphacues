---
name: AlphaCues MVP Design
overview: Design a production-ready modular monolith MVP for AlphaCues -- a stock market alert and notification web app built with Flutter (frontend) + Flask (backend) + PostgreSQL + Redis, deployed on Vercel + Railway, with real-time market data via Alpaca/Alpha Vantage APIs.
todos:
  - id: architecture-md
    content: Write ARCHITECTURE.md with system overview, frontend/backend structure, API design, database design, data flow, and key decisions
    status: pending
  - id: implementation-plan-md
    content: Write IMPLEMENTATION_PLAN.md with Phase 1 (foundation), Phase 2 (core features), Phase 3 (enhancements) -- step-by-step tasks, file breakdowns, dependencies, risks
    status: pending
  - id: readme-md
    content: Write README.md with project overview, tech stack, setup instructions, env vars, local run guide, and usage flow
    status: pending
isProject: false
---

# AlphaCues MVP -- Full-Stack Architecture and Implementation Plan

This plan delivers three documents: `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, and `README.md` for a production-grade stock market alert and notification web app.

---

## 1. ARCHITECTURE.md

### 1.1 System Overview

AlphaCues is a **modular monolith** -- a single deployable Flask application with strict module boundaries, one PostgreSQL database (tables namespaced per module), and Redis for caching/queues/pub-sub. The frontend is a Flutter Web app (compiled to JS, deployed to Vercel CDN). Real-time stock data streams over WebSockets from Alpaca Markets API into the Flask backend, which fans out alerts via Redis pub-sub to connected clients through Flask-SocketIO.

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

**Scale target**: 3,000-5,000 concurrent users. Achieved via:
- Gunicorn with gevent workers (async I/O, ~1,000 connections per worker, 4 workers = 4,000+)
- Redis caching for hot data (stock quotes cached 5s TTL, watchlists 30s TTL)
- PostgreSQL connection pooling (PgBouncer or SQLAlchemy pool, 20 connections)
- Celery workers for background alert evaluation (decoupled from request cycle)
- CDN-served Flutter web app (zero backend load for static assets)

### 1.2 Frontend Structure (Flutter Web)

**State Management**: Riverpod 3.x -- chosen for superior async handling (`AsyncValue` for loading/error/data states), compile-time safety, and natural fit for reactive market data streams.

**Charting**: `fl_chart` 1.0.0 -- mature library with native CandlestickChart widget, horizontal scroll/zoom, and real-time data update support.

**Project Structure**:
```
alphacues_web/
  lib/
    main.dart
    app.dart
    core/                        # Shared foundation
      config/
        app_config.dart          # Environment, feature flags
        api_config.dart          # Base URLs, timeouts
        theme.dart               # Colors (#7061F3 CTA), Inter font, spacing
      constants/
      utils/
        formatters.dart          # Price, date, percent formatters
      widgets/                   # Shared widgets (buttons, cards, loaders)
      services/
        api_client.dart          # HTTP client (dio), interceptors, retry
        websocket_service.dart   # SocketIO client for real-time
        auth_service.dart        # Supabase auth wrapper
        storage_service.dart     # SharedPreferences / secure storage
    features/
      auth/
        data/                    # Repositories, DTOs
        domain/                  # Models, contracts
        presentation/            # Screens, widgets, providers
      watchlist/
        data/
        domain/
        presentation/
      dashboard/
        data/
        domain/
        presentation/
      alerts/
        data/
        domain/
        presentation/
      screener/
        data/
        domain/
        presentation/
      portfolio/
        data/
        domain/
        presentation/
    shared/
      contracts/                 # Shared data contracts (DTOs)
        user_contract.dart
        stock_contract.dart
        alert_contract.dart
  test/
    features/
      auth/
      watchlist/
      ...
  web/
    index.html                   # Entry point with cache-busting
```

**UI/UX Design System**:
- Primary CTA color: `#7061F3` (purple)
- Font: Inter (Google Fonts)
- Background: White (`#FFFFFF`), Surface: `#F8F9FA`
- Uptrend: `#22C55E` (green), Downtrend: `#EF4444` (red)
- Spacing: 8px grid system
- Components: Material 3 with custom theme overlay

### 1.3 Backend Structure (Flask Modular Monolith)

Uses **Application Factory Pattern** + **Blueprints** with strict module boundaries. Each module exposes a public API (its `__init__.py` re-exports); no module imports another module's internal files.

**Project Structure**:
```
alphacues_api/
  app/
    __init__.py                  # create_app() factory
    extensions.py                # db, migrate, redis, celery, socketio, limiter
    config/
      base.py                    # Shared config
      development.py
      production.py
      testing.py
    modules/
      auth/
        __init__.py              # Public API: register, login, verify_otp, get_user
        routes.py                # Blueprint: /api/v1/auth/*
        services.py              # Business logic
        models.py                # User, OTPCode tables
        schemas.py               # Marshmallow serialization
        tests/
          test_auth.py
      portfolio/
        __init__.py
        routes.py                # /api/v1/portfolio/*
        services.py
        models.py                # Portfolio, Holding tables
        schemas.py
        tests/
      watchlist/
        __init__.py
        routes.py                # /api/v1/watchlist/*
        services.py
        models.py                # Watchlist, WatchlistItem tables
        schemas.py
        tests/
      alerts/
        __init__.py
        routes.py                # /api/v1/alerts/*
        services.py
        models.py                # Alert, Notification, AlertHistory tables
        tasks.py                 # Celery tasks: evaluate_alerts, send_notification
        schemas.py
        tests/
      screener/
        __init__.py
        routes.py                # /api/v1/screener/*
        services.py
        models.py                # ScreenerPreset, ScreenerResult tables
        schemas.py
        tests/
      market_data/
        __init__.py
        routes.py                # /api/v1/market/*
        services.py              # Alpaca + Alpha Vantage client wrappers
        models.py                # MarketDataCache table (fallback)
        tasks.py                 # Celery: stream_prices, fetch_fundamentals
        schemas.py
        tests/
    shared/
      contracts/                 # Shared data shapes (prevents upstream breakage)
        user_contract.py
        stock_contract.py
        alert_contract.py
      middleware/
        auth_middleware.py       # JWT verification decorator
        rate_limiter.py          # Flask-Limiter config
        error_handler.py         # Global error handlers
      utils/
        feature_flags.py         # DB-backed feature flag reader
        validators.py            # Input validation helpers
        cache.py                 # Redis cache helpers (get/set/invalidate)
    migrations/                  # Alembic migration scripts
  celery_worker.py               # Celery app entry point
  wsgi.py                        # Gunicorn entry point
  Procfile
  requirements.txt
  runtime.txt
  tests/
    conftest.py                  # Shared fixtures
    integration/
```

**Key Backend Decisions**:
- **Celery + Redis** (not RQ): Celery is the industry standard for production task queues. Handles alert evaluation, price streaming fan-out, and email sending. Visibility timeout tuned to prevent duplicate alerts.
- **Flask-SocketIO + gevent**: Real-time push to clients for live price updates and alert triggers. Gevent provides async I/O without threads.
- **Flask-Limiter**: Rate limiting per endpoint (e.g., 5 OTP requests/min, 60 API calls/min per user).
- **Flask-Migrate (Alembic)**: Database migrations run as Railway pre-deploy commands.
- **Marshmallow**: Schema validation and serialization -- enforces shared data contracts.

### 1.4 API Design (Endpoints)

All endpoints prefixed with `/api/v1/`. Auth required unless noted.

**Auth Module** (`/api/v1/auth`):
- `POST /register` -- Register with email (no auth)
- `POST /login` -- Request OTP to email (no auth)
- `POST /verify-otp` -- Verify OTP, return JWT (no auth)
- `POST /refresh` -- Refresh access token
- `GET /me` -- Get current user profile
- `PUT /me` -- Update profile
- `POST /logout` -- Invalidate session

**Watchlist Module** (`/api/v1/watchlist`):
- `GET /` -- List user's watchlists
- `POST /` -- Create watchlist
- `GET /:id` -- Get watchlist with current prices
- `PUT /:id` -- Update watchlist name
- `DELETE /:id` -- Delete watchlist
- `POST /:id/symbols` -- Add symbols to watchlist
- `DELETE /:id/symbols/:symbol` -- Remove symbol

**Portfolio Module** (`/api/v1/portfolio`):
- `GET /` -- Get user portfolio summary
- `POST /holdings` -- Add holding (manual entry)
- `PUT /holdings/:id` -- Update holding
- `DELETE /holdings/:id` -- Remove holding
- `GET /performance` -- Portfolio performance over time

**Alerts Module** (`/api/v1/alerts`):
- `GET /` -- List user's alerts
- `POST /` -- Create alert (price target, % change, volume spike, etc.)
- `GET /:id` -- Get alert details
- `PUT /:id` -- Update alert
- `DELETE /:id` -- Delete alert
- `GET /history` -- Alert trigger history
- `GET /notifications` -- User notification feed
- `PUT /notifications/:id/read` -- Mark notification read
- `PUT /notifications/read-all` -- Mark all read

**Screener Module** (`/api/v1/screener`):
- `POST /scan` -- Run screen with filters (P/E, RSI, market cap, etc.)
- `GET /presets` -- List saved screen presets
- `POST /presets` -- Save screen preset
- `DELETE /presets/:id` -- Delete preset
- `GET /indicators` -- List available indicators/filters

**Market Data Module** (`/api/v1/market`):
- `GET /quote/:symbol` -- Current quote (cached 5s in Redis)
- `GET /quotes` -- Batch quotes (query param: `symbols=AAPL,TSLA,...`)
- `GET /history/:symbol` -- Historical OHLCV (query params: `timeframe`, `start`, `end`)
- `GET /fundamentals/:symbol` -- Company fundamentals (Alpha Vantage, cached 1hr)
- `GET /search` -- Symbol search/autocomplete
- `WS /stream` -- WebSocket: subscribe to real-time price updates

### 1.5 Database Design

Single PostgreSQL database. Tables are logically grouped by module. All tables include `id` (UUID PK), `created_at`, `updated_at`.

```mermaid
erDiagram
    users {
        uuid id PK
        string email UK
        string display_name
        jsonb preferences
        timestamp email_verified_at
        timestamp last_login_at
        timestamp created_at
        timestamp updated_at
    }

    otp_codes {
        uuid id PK
        uuid user_id FK
        string code
        string purpose
        timestamp expires_at
        boolean is_used
        timestamp created_at
    }

    watchlists {
        uuid id PK
        uuid user_id FK
        string name
        int sort_order
        timestamp created_at
        timestamp updated_at
    }

    watchlist_items {
        uuid id PK
        uuid watchlist_id FK
        string symbol
        int sort_order
        timestamp added_at
    }

    portfolios {
        uuid id PK
        uuid user_id FK
        string name
        timestamp created_at
        timestamp updated_at
    }

    holdings {
        uuid id PK
        uuid portfolio_id FK
        string symbol
        decimal quantity
        decimal avg_cost_basis
        timestamp purchased_at
        timestamp created_at
        timestamp updated_at
    }

    alerts {
        uuid id PK
        uuid user_id FK
        string symbol
        string alert_type
        string condition
        decimal target_value
        boolean is_active
        boolean is_triggered
        jsonb metadata
        timestamp last_triggered_at
        timestamp created_at
        timestamp updated_at
    }

    alert_history {
        uuid id PK
        uuid alert_id FK
        decimal triggered_at_price
        timestamp triggered_at
    }

    notifications {
        uuid id PK
        uuid user_id FK
        uuid alert_id FK
        string channel
        string title
        string body
        boolean is_read
        timestamp read_at
        timestamp created_at
    }

    screener_presets {
        uuid id PK
        uuid user_id FK
        string name
        jsonb filters
        timestamp created_at
        timestamp updated_at
    }

    feature_flags {
        uuid id PK
        string flag_key UK
        boolean is_enabled
        jsonb metadata
        timestamp created_at
        timestamp updated_at
    }

    users ||--o{ otp_codes : "has"
    users ||--o{ watchlists : "owns"
    users ||--o{ portfolios : "owns"
    users ||--o{ alerts : "creates"
    users ||--o{ notifications : "receives"
    users ||--o{ screener_presets : "saves"
    watchlists ||--o{ watchlist_items : "contains"
    portfolios ||--o{ holdings : "contains"
    alerts ||--o{ alert_history : "triggers"
    alerts ||--o{ notifications : "generates"
```

**Key Indexes**:
- `users.email` -- unique, for login lookups
- `otp_codes(user_id, purpose, is_used)` -- OTP verification
- `watchlist_items(watchlist_id, symbol)` -- unique composite, prevent duplicates
- `alerts(user_id, is_active)` -- active alert queries
- `alerts(symbol, is_active)` -- alert evaluation per symbol
- `notifications(user_id, is_read, created_at DESC)` -- notification feed
- `feature_flags.flag_key` -- unique, fast flag lookups
- `holdings(portfolio_id)` -- portfolio queries

### 1.6 Data Flow Diagram

**Real-Time Price Alert Flow:**
1. Celery worker connects to Alpaca WebSocket, subscribes to all symbols that have active alerts.
2. As price ticks arrive, worker publishes to Redis pub-sub channel `prices:{symbol}`.
3. Alert evaluator (Celery periodic task, runs every 5s) reads latest prices from Redis, compares against active alerts in DB.
4. When an alert triggers: (a) insert into `alert_history`, (b) create `notification` row, (c) publish to Redis channel `notifications:{user_id}`, (d) queue SendGrid email task.
5. Flask-SocketIO listens on Redis pub-sub, forwards price updates and notifications to connected WebSocket clients.
6. Flutter web app receives WebSocket event, Riverpod provider updates UI reactively.

**User Authentication Flow:**
1. User enters email -> Flutter calls `POST /auth/login`.
2. Flask generates 6-digit OTP, stores in `otp_codes` (5-min TTL), queues SendGrid email via Celery.
3. User enters OTP -> Flutter calls `POST /auth/verify-otp`.
4. Flask verifies OTP, creates/updates user in Supabase Auth, returns JWT (access + refresh tokens).
5. Flutter stores tokens in secure storage, attaches to all subsequent API requests.

**Screener Flow:**
1. User selects filters (e.g., P/E < 20, RSI < 30, Market Cap > 1B) in Flutter UI.
2. Flutter calls `POST /screener/scan` with filter JSON.
3. Flask screener service queries Alpha Vantage for fundamentals (cached 1hr in Redis), computes technical indicators from Alpaca historical data.
4. Results filtered, sorted, and returned. User can save as preset.

### 1.7 Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| **Architecture** | Modular monolith | Single deploy, simpler ops for MVP. Module boundaries enforce separation; feature flags enable future extraction to microservices. |
| **Market data (real-time)** | Alpaca Markets API (free Basic plan) | 30 WebSocket subscriptions on free tier, IEX exchange data, Python SDK (`alpaca-py`), no payment required beyond brokerage account signup. |
| **Market data (fundamentals)** | Alpha Vantage API (free tier, 25 req/day) | Covers fundamentals, technicals (50+ indicators), 20+ years history. Heavy caching (1hr TTL) keeps within rate limits. |
| **State management** | Riverpod 3.x | Best async handling for market data streams, compile-time safe, simpler than BLoC for small team. |
| **Charting** | fl_chart 1.0.0 | Native CandlestickChart, scroll/zoom, active maintenance, 7k+ GitHub stars. |
| **Task queue** | Celery + Redis | Industry standard. Handles alert evaluation, email sending, price streaming. Visibility timeout tuned for financial ops. |
| **Real-time transport** | Flask-SocketIO + Redis pub-sub | Server-push for live prices and alerts. Redis adapter enables horizontal scaling later. |
| **Auth** | Supabase Auth + custom OTP via SendGrid | Supabase handles JWT issuance and user management. Custom OTP flow via SendGrid gives full control over email templates and branding. |
| **Feature flags** | DB-backed (feature_flags table) | Read on each request via Redis cache (10s TTL). No vendor dependency. Toggle behavior via SQL or admin endpoint. Zero code deploy. |
| **Shared data contracts** | Marshmallow schemas + Flutter DTOs | Same field names enforced on both sides. Prevents the `userId` vs `id` breakage scenario. Contract tests validate shape. |

---

## 2. IMPLEMENTATION_PLAN.md

### Phase 1: MVP Foundation (Weeks 1-2)

**Goal**: Flask app boots, connects to DB and Redis, auth works end-to-end, Flutter shell app loads with login flow.

**Tasks** (in dependency order):

1. **Project scaffolding -- Backend**
   - Initialize Flask app with factory pattern in `app/__init__.py`
   - Set up `extensions.py` (SQLAlchemy, Migrate, Redis, Celery, SocketIO, Limiter)
   - Create config classes (`base.py`, `development.py`, `production.py`, `testing.py`)
   - Create `wsgi.py`, `celery_worker.py`, `Procfile`, `requirements.txt`, `runtime.txt`
   - Set up `.env.example` with all required variables
   - Files: `app/__init__.py`, `app/extensions.py`, `app/config/*.py`, `wsgi.py`, `celery_worker.py`

2. **Database setup**
   - Initialize Alembic migrations (`flask db init`)
   - Create `feature_flags` model and initial migration
   - Seed default feature flags (`enable_alerts`, `enable_screener`, `enable_portfolio`)
   - Files: `app/shared/utils/feature_flags.py`, `app/modules/*/models.py`, `migrations/`

3. **Shared infrastructure**
   - Build `auth_middleware.py` (JWT verification decorator)
   - Build `error_handler.py` (global exception handler returning consistent JSON errors)
   - Build `rate_limiter.py` configuration
   - Build `cache.py` (Redis get/set/invalidate helpers)
   - Build `validators.py` (email format, symbol format, pagination params)
   - Build shared data contracts (`user_contract.py`, `stock_contract.py`, `alert_contract.py`)
   - Files: `app/shared/middleware/*.py`, `app/shared/utils/*.py`, `app/shared/contracts/*.py`

4. **Auth module -- Backend**
   - Create `User`, `OTPCode` models with migrations
   - Build auth service: register, generate OTP, verify OTP, issue JWT via Supabase
   - Build auth routes blueprint (`/api/v1/auth/*`)
   - Integrate SendGrid for OTP emails via Celery task
   - Rate limit: 5 OTP requests/minute/IP
   - Write unit tests for auth service
   - Files: `app/modules/auth/*.py`, `app/modules/auth/tests/test_auth.py`

5. **Project scaffolding -- Frontend**
   - Create Flutter web project (`flutter create --platforms web alphacues_web`)
   - Set up Riverpod, dio, flutter_secure_storage, go_router, google_fonts
   - Configure theme (`#7061F3` primary, Inter font, Material 3)
   - Build `api_client.dart` with interceptors (auth header injection, error mapping, retry)
   - Build `auth_service.dart` (Supabase client wrapper)
   - Files: `lib/core/config/*.dart`, `lib/core/services/*.dart`, `lib/core/widgets/*.dart`

6. **Auth module -- Frontend**
   - Build login screen (email input -> OTP input -> dashboard redirect)
   - Build OTP verification screen with countdown timer
   - Auth state provider (Riverpod): manages token storage, auto-refresh, logout
   - Route guards: redirect unauthenticated users to login
   - Files: `lib/features/auth/presentation/*.dart`, `lib/features/auth/data/*.dart`

7. **CI/CD setup**
   - GitHub Actions workflow: lint + test on PR
   - Railway auto-deploy from `main` branch (backend)
   - Vercel auto-deploy from `main` branch (frontend)
   - Pre-deploy migration command on Railway
   - Files: `.github/workflows/ci.yml`

**Risks/Blockers**:
- Supabase free tier has a 50,000 monthly active user limit (sufficient for MVP)
- Alpaca requires brokerage account signup for API keys (no money deposit needed)
- Railway free tier has usage limits; may need Starter plan ($5/mo) for always-on

### Phase 2: Core Features (Weeks 3-5)

**Goal**: Watchlist, market data, charts, alerts, and notifications fully functional.

**Tasks**:

8. **Market data module -- Backend**
   - Build Alpaca client wrapper (REST for historical, WebSocket for real-time)
   - Build Alpha Vantage client wrapper (fundamentals, technicals)
   - Celery task: `stream_prices` -- connects to Alpaca WS, publishes to Redis pub-sub
   - Celery task: `fetch_fundamentals` -- periodic batch fetch, cache 1hr in Redis
   - Market data routes: `/quote/:symbol`, `/quotes`, `/history/:symbol`, `/fundamentals/:symbol`, `/search`
   - Redis caching: quotes 5s TTL, fundamentals 1hr TTL, history 5min TTL
   - Files: `app/modules/market_data/*.py`
   - Depends on: Task 1, 3

9. **WebSocket infrastructure**
   - Configure Flask-SocketIO with Redis message queue adapter
   - Implement namespace `/stream` for real-time price updates
   - Client authentication via JWT on WebSocket connect
   - Implement Flutter `websocket_service.dart` (socket_io_client package)
   - Riverpod `StreamProvider` for live prices
   - Files: `app/extensions.py` (socketio config), `lib/core/services/websocket_service.dart`
   - Depends on: Task 8

10. **Watchlist module -- Backend + Frontend**
    - Backend: `Watchlist`, `WatchlistItem` models, service, routes, tests
    - Frontend: Watchlist list screen, add/remove symbols, live price display via WS
    - Drag-to-reorder symbols, swipe-to-delete
    - Files: `app/modules/watchlist/*.py`, `lib/features/watchlist/**`
    - Depends on: Task 8, 9

11. **Dashboard module -- Frontend**
    - Market overview: major indices (S&P 500, NASDAQ, DOW) with mini sparkline charts
    - Top movers (gainers/losers) -- data from Alpaca
    - User's watchlist summary widget
    - Portfolio summary widget (if holdings exist)
    - Notification bell with unread count badge
    - Files: `lib/features/dashboard/**`
    - Depends on: Task 8, 9, 10

12. **Charts feature -- Frontend**
    - CandlestickChart (fl_chart) for individual stock view
    - Timeframe selector: 1D, 1W, 1M, 3M, 1Y, ALL
    - Volume bars overlay
    - Price tooltip on hover/tap
    - Stock detail screen: chart + quote + fundamentals summary
    - Files: `lib/features/dashboard/presentation/widgets/stock_chart.dart`, `lib/features/dashboard/presentation/screens/stock_detail_screen.dart`
    - Depends on: Task 8

13. **Alerts module -- Backend**
    - `Alert`, `AlertHistory`, `Notification` models, migrations
    - Alert types: price above/below, percentage change, volume spike
    - Celery periodic task: `evaluate_alerts` (every 5s) -- compare Redis prices vs active alerts
    - On trigger: insert history, create notification, publish Redis event, queue email
    - Alert routes: CRUD + history + notifications
    - Notification routes: list, mark read, mark all read
    - Unit tests for alert evaluation logic
    - Files: `app/modules/alerts/*.py`
    - Depends on: Task 8

14. **Alerts module -- Frontend**
    - Create alert form: select symbol, condition, target value
    - Active alerts list with status (active/triggered)
    - Alert history view
    - Notification feed (dropdown from bell icon)
    - Real-time notification toast via WebSocket
    - Files: `lib/features/alerts/**`
    - Depends on: Task 9, 13

15. **Portfolio module -- Backend + Frontend**
    - Backend: `Portfolio`, `Holding` models, service, routes
    - Manual entry of holdings (symbol, quantity, avg cost)
    - Performance calculation: current value, P/L, % change (using live quotes)
    - Frontend: holdings list, add/edit/remove, portfolio summary card
    - Files: `app/modules/portfolio/*.py`, `lib/features/portfolio/**`
    - Depends on: Task 8

**Risks/Blockers**:
- Alpaca free tier limits: 30 WS subscriptions. Mitigation: batch symbols across users, only subscribe to symbols with active alerts/watchers. Rotate subscriptions based on demand.
- Alpha Vantage free tier: 25 requests/day. Mitigation: aggressive caching (1hr), batch requests, pre-fetch popular symbols during off-hours.
- Flask-SocketIO with gevent requires monkey-patching; test early for compatibility issues.

### Phase 3: Enhancements (Weeks 6-7)

**Goal**: Screener, polish, testing, performance hardening, deployment hardening.

**Tasks**:

16. **Screener module -- Backend + Frontend**
    - Backend: `ScreenerPreset` model, scan service, routes
    - Supported filters: market cap, P/E, EPS, RSI, 50/200 SMA, volume, sector
    - Compute indicators from cached historical data (no real-time requirement)
    - Save/load presets
    - Frontend: filter form with dropdowns/sliders, results table, save preset
    - Files: `app/modules/screener/*.py`, `lib/features/screener/**`
    - Depends on: Task 8

17. **Feature flags admin**
    - Backend: `GET /api/v1/admin/flags`, `PUT /api/v1/admin/flags/:key` (admin-only)
    - All feature-gated endpoints check flag before executing
    - Redis-cached flag reads (10s TTL) for zero-latency checks
    - Files: `app/shared/utils/feature_flags.py`, new admin blueprint
    - Depends on: Task 2

18. **Testing and quality**
    - Backend: pytest suite -- unit tests for each module's service layer, integration tests for API routes
    - Frontend: widget tests for key screens, unit tests for providers
    - Contract tests: validate backend response shapes match Flutter DTOs
    - Load test: Locust script simulating 1,000 concurrent users hitting dashboard + watchlist
    - Files: `tests/`, `alphacues_web/test/`, `load_tests/locustfile.py`

19. **Performance hardening**
    - Add database indexes per section 1.5
    - Configure PgBouncer or SQLAlchemy connection pool (min=5, max=20)
    - Redis connection pool (max=10)
    - Implement request-level caching for repeated queries within same request
    - Gzip compression middleware
    - Frontend: lazy-load feature modules, image optimization, debounce search input
    - Review and optimize N+1 queries with SQLAlchemy eager loading

20. **Security hardening**
    - CORS configuration (allow only Vercel domain)
    - CSRF protection for non-API routes
    - SQL injection prevention: all queries via SQLAlchemy ORM (never raw SQL)
    - Input sanitization on all user inputs
    - Rate limiting: global 100 req/min/IP, auth endpoints 5/min, screener 10/min
    - Helmet-equivalent headers (X-Content-Type-Options, X-Frame-Options, etc.)
    - Secrets: all keys in environment variables, never in code
    - JWT: short-lived access tokens (15min), longer refresh tokens (7 days)

21. **Deployment and monitoring**
    - Railway: production environment variables, custom domain, health check endpoint
    - Vercel: production build, cache-busting config, custom domain
    - Structured logging (JSON format) with request ID correlation
    - Error tracking: Sentry integration (backend + frontend)
    - Health check endpoint: `GET /api/v1/health` (checks DB, Redis, Alpaca WS)
    - Files: `app/shared/middleware/logging.py`, `.github/workflows/deploy.yml`

---

## 3. README.md

### Content Outline

**Project Overview**: AlphaCues is a real-time stock market alert and notification web app. Track watchlists, set price alerts, screen stocks, and monitor your portfolio -- all with live market data.

**Tech Stack**:
- Frontend: Flutter Web 3.x, Riverpod 3.x, fl_chart 1.0.0, dio, go_router
- Backend: Flask 3.x, SQLAlchemy 2.x, Celery 5.x, Flask-SocketIO 5.x, Marshmallow 3.x
- Database: PostgreSQL 16, Redis 7
- Auth: Supabase Auth + SendGrid (OTP emails)
- Market Data: Alpaca Markets API (real-time), Alpha Vantage API (fundamentals)
- Deployment: Railway (backend + DB + Redis), Vercel (frontend)

**Environment Variables** (`.env.example`):
```
# Flask
FLASK_ENV=development
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://user:pass@localhost:5432/alphacues
REDIS_URL=redis://localhost:6379/0

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Alpaca Markets
ALPACA_API_KEY=your-alpaca-key
ALPACA_SECRET_KEY=your-alpaca-secret
ALPACA_BASE_URL=https://paper-api.alpaca.markets

# Alpha Vantage
ALPHA_VANTAGE_API_KEY=your-av-key

# SendGrid
SENDGRID_API_KEY=your-sendgrid-key
SENDGRID_FROM_EMAIL=alerts@alphacues.com

# Feature Flags (defaults)
FF_ENABLE_ALERTS=true
FF_ENABLE_SCREENER=true
FF_ENABLE_PORTFOLIO=true
```

**Local Setup**:
- Backend: `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && flask db upgrade && flask run`
- Celery worker: `celery -A celery_worker.celery worker --loglevel=info`
- Frontend: `cd alphacues_web && flutter pub get && flutter run -d chrome`
- Prerequisites: Python 3.12+, Flutter 3.x, PostgreSQL 16, Redis 7

**Basic Usage Flow**: Register with email -> receive OTP -> verify -> land on dashboard -> add symbols to watchlist -> set price alerts -> get notified when triggered.
