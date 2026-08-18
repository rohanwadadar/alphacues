# Alpha Cues MVP - API Contract Changelog

All notable contract-relevant changes (new endpoints, additive fields, deprecation notices) to the Alpha Cues MVP API are documented in this file module by module.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to `/api/v1` compatibility rules (breaking changes require `/api/v2`).

---

## [Unreleased]

### `admin`
- **New Endpoints**:
  - `GET /api/v1/admin/flags` — List all feature flags (admin only).
  - `GET /api/v1/admin/flags/<flag_key>` — Get single feature flag detail (admin only).
  - `PATCH /api/v1/admin/flags/<flag_key>` — Update flag `is_enabled` status (admin only).
- **Fixtures**: Committed `admin/flag_list.json` and `admin/flag_item.json`.

### `alerts`
- **Contracts Frozen**:
  - `POST /api/v1/alerts` — Create alert.
  - `GET /api/v1/alerts` — List alerts with cursor pagination.
  - `DELETE /api/v1/alerts/:id` — Delete alert.
- **Fixtures**: Committed `alerts/alert_list.json`, `alerts/alert_item.json`, and `alerts/alert_triggered_event.json`.
- **Migration Safety**: Added migration test suite verifying additive field handling and nullability protection.

### `market`
- **Contracts Frozen**:
  - `GET /api/v1/market/quote` — Current stock quote.
  - `GET /api/v1/market/bars` — Historical bar series.
  - `GET /api/v1/market/snapshot` — Multi-symbol market snapshot.
  - `GET /api/v1/market/search` — Symbol search (rate limited 30/min).
  - `GET /api/v1/market/movers` — Market gainers and losers.
  - `GET /api/v1/market/fundamentals` — Fundamental financial indicators.
  - `GET /api/v1/dashboard` — Combined gainers & losers dashboard summary.
- **Fixtures**: Committed `market/` fixtures for quote, bars, snapshot, search, movers, and fundamentals.

### `notifications`
- **Contracts Frozen**:
  - `GET /api/v1/notifications` — User notifications list with cursor pagination.
- **Fixtures**: Committed `notifications/notification_list.json`.

### `portfolio`
- **Contracts Frozen**:
  - `GET /api/v1/portfolio/summary` — Portfolio valuation and total return.
- **Fixtures**: Committed `portfolio/portfolio_summary.json`.

### `screener`
- **New Endpoints**:
  - `POST /api/v1/screener/run` (and `/scan` alias) — Execute market strategy scan.
  - `GET /api/v1/screener/strategies` — List user saved strategies.
  - `POST /api/v1/screener/strategies` — Create saved strategy.
  - `GET /api/v1/screener/strategies/:id` — Get strategy detail.
  - `PUT /api/v1/screener/strategies/:id` — Update strategy detail.
  - `DELETE /api/v1/screener/strategies/:id` — Delete strategy.
  - `POST /api/v1/screener/strategies/:id/run` — Run saved strategy.
- **Fixtures**: Committed `screener/screener_results.json`, `screener/screener_strategy.json`, and `screener/screener_strategy_list.json`.

### `user` / `auth`
- **Contracts Frozen**:
  - `POST /api/v1/auth/send-otp` — Request login OTP.
  - `POST /api/v1/auth/verify-otp` — Verify OTP and obtain JWT tokens.
  - `POST /api/v1/auth/refresh` — Refresh access token.
  - `POST /api/v1/auth/logout` — Revoke refresh token.
- **Fixtures**: Committed `user/` fixtures for OTP challenge, verification, refresh, and error envelopes.

### `watchlist`
- **Contracts Frozen**:
  - `GET /api/v1/watchlists` — List watchlists.
  - `POST /api/v1/watchlists` — Create watchlist.
  - `GET /api/v1/watchlists/:id` — Watchlist items & live price detail.
  - `POST /api/v1/watchlists/:id/symbols` — Add symbol to watchlist.
  - `DELETE /api/v1/watchlists/:id/symbols/:symbol` — Remove symbol.
- **Fixtures**: Committed `watchlist/watchlist_list.json` and `watchlist/watchlist_detail.json`.

---

## [1.0.0] - 2026-05-13
- Initial Phase 1 & 2 MVP API release with canonical `/api/v1` envelope and standard error handling catalog.
