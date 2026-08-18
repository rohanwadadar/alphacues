# 📈 TradeApp 2026 — Flutter Trading Application

> A full-featured stock trading companion built with Flutter.  
> Real-time data · Portfolio tracking · Strategy screener · Paper trading simulator

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Folder Structure](#-folder-structure)
3. [API Endpoints & Services](#-api-endpoints--services)
4. [Environment Configuration](#-environment-configuration)
5. [Feature Map](#-feature-map)
6. [Static Data Migration Guide](#-static-data-migration-guide)
7. [Security Architecture](#-security-architecture)
8. [Backend Integration](#-backend-integration)
9. [Running the App](#-running-the-app)
10. [Dependencies](#-dependencies)

---

## 🧭 Project Overview

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| Market Data | Alpaca Markets API |
| News & Fundamentals | Alpha Vantage API |
| **Backend API** | **AlphaCues Microservices (Spring Boot & Kotlin)** |
| **Auth** | **Spring Security + JWT + Biometric/PIN** |
| Local Storage | SharedPreferences · flutter_secure_storage |
| Database | MySQL (User) · TimescaleDB (Portfolio) · Redis (Cache) |
| Messaging | RabbitMQ · Kafka |
| Charts | fl_chart · candlesticks · interactive_chart |

---

## 📁 Folder Structure

```
lib/
│
├── core/                          ← Shared infrastructure
│   ├── core.dart                  ← Single barrel export (import this)
│   ├── config/
│   │   ├── env.dart               ← ALL API keys, base URLs, endpoints
│   │   └── app_constants.dart     ← Colors, spacing, text styles
│   ├── services/
│   │   ├── alpaca_service.dart    ← Alpaca Markets HTTP client
│   │   ├── alpha_vantage_service.dart ← Alpha Vantage HTTP client
│   │   └── backend_service.dart   ← Custom backend REST stubs
│   ├── models/
│   │   ├── stock_model.dart       ← StockAsset data class
│   │   └── strategy_model.dart    ← ScreenerStrategy data class
│   └── utils/
│       └── format_utils.dart      ← Currency, percent, date helpers
│
├── features/                      ← One sub-folder per feature
│   ├── auth/                      ← Login, PIN, biometric
│   ├── dashboard/                 ← Home / main.dart
│   ├── portfolio/                 ← portfolio.dart
│   ├── stock/                     ← stock.dart, stock_details.dart
│   ├── screener/                  ← screener.dart
│   ├── trending/                  ← treanding.dart
│   ├── wishlist/                  ← wishlist.dart, wishlistholding_section.dart
│   ├── news/                      ← news.dart, newsmail.dart
│   ├── security/                  ← security_screen.dart, set_pin_screen.dart
│   │                                 two_factor.dart, app_lock_wrapper.dart
│   │                                 biometric_service.dart, secure_storage_service.dart
│   │                                 security_settings_tile.dart, pin_lock_screen.dart
│   ├── profile/                   ← profile.dart, edit_profile.dart, bio.dart
│   │                                 Investment_profile.dart, pinfo.dart
│   ├── notifications/             ← notification.dart, alerts.dart
│   ├── simulator/                 ← simulator.dart, stock_stimulator.dart
│   └── trading/                   ← buy.dart, sell.dart, order.dart
│                                    topup.dart, report.dart, tax.dart, reward.dart
│
├── shared/                        ← Reusable UI components
│   ├── widgets/                   ← Common widgets (buttons, cards, etc.)
│   └── theme/                     ← ThemeData, MaterialApp setup
│
└── main.dart                      ← App entry point
```

> **Note:** Files in `features/` are NOT moved yet — the folders represent  
> the **target** structure. Move files as you refactor each feature.

---

## 🌐 API Endpoints & Services

### 1. Alpaca Markets

| Purpose | Method | Endpoint | Used By |
|---|---|---|---|
| List tradable assets | GET | `/v2/assets?status=active&asset_class=us_equity` | Screener |
| Get positions | GET | `/v2/positions` | Portfolio |
| Get account | GET | `/v2/account` | Dashboard |
| Order history | GET | `/v2/orders?status=all` | Orders |
| Place order | POST | `/v2/orders` | Buy / Sell |
| OHLCV bars | GET | `/v2/stocks/bars?symbols=...` | Charts |
| Live snapshot | GET | `/v2/stocks/snapshots?symbols=...` | Stock list |

**Base URLs:**
- Market Data: `https://data.alpaca.markets`
- Trading: `https://paper-api.alpaca.markets` ← **paper trading, safe to use**

---

### 2. Alpha Vantage

| Purpose | Method | Endpoint | Used By |
|---|---|---|---|
| News sentiment | GET | `?function=NEWS_SENTIMENT&tickers=...` | Trending, Stock Details |
| Symbol search | GET | `?function=SYMBOL_SEARCH&keywords=...` | Trending search |
| Daily time series | GET | `?function=TIME_SERIES_DAILY&symbol=...` | Charts, Simulator |
| Earnings / EPS | GET | `?function=EARNINGS&symbol=...` | Fundamentals |

**Base URL:** `https://www.alphavantage.co/query`

> ⚠️ Free tier: **25 requests/day**. Upgrade key for production.

---

### 3. Custom Backend (AlphaCues API — Spring Boot Microservices)

A high-performance enterprise backend with dedicated services for every domain. Entry is managed through the **API Gateway**.

| Service | Port | Responsibility | Core Tech |
|---|---|---|---|
| **API Gateway** | 9002/3 | Routing, Rate Limiting, JWT Guard | Spring Cloud Gateway |
| **Auth Service** | 9001 | Registration, Login, 2FA | Spring Security / Redis |
| **User Service** | 9002 | Profiles, Portfolio tracking | Spring Data JPA / MySQL |
| **Suggestion Svc** | 9009 | Real-time trading signals | WebSockets / Kafka |
| **File Service** | 9005 | Image uploads & Static assets | Minio (S3 Compatible) |
| **Notification** | 9004 | Push, Email, SMS alerts | RabbitMQ |

> 🚀 **Note:** For real-time price or suggestion updates, the app connects to the **Suggestion Load Balancer (Nginx)** on port `9009`.

---

## ⚙️ Environment Configuration

**All API keys and URLs live in one file:**

```
lib/core/config/env.dart
```

### How to update a key

1. Open `lib/core/config/env.dart`
2. Find the constant (e.g. `alphaVantageKey`)
3. Replace the value
4. Hot-reload — no other file needs changing

### For production

Use [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv):

```dart
// env.dart (prod version)
static String get alphaVantageKey => dotenv.env['ALPHA_KEY']!;
```

Add `.env` to `.gitignore` and inject via CI/CD.

---

## 🗺️ Feature Map

| Screen File | Feature | Data Source | Status |
|---|---|---|---|
| `main.dart` | Dashboard / Home | Static | ⚠️ Static |
| `portfolio.dart` | Holdings & P&L | Static | ⚠️ Static |
| `stock.dart` | Stock list | Alpaca snapshots | 🔌 Live |
| `stock_details.dart` | Chart + fundamentals | Alpaca + Alpha Vantage | 🔌 Live |
| `screener.dart` | Strategy screener | Alpaca assets | 🔌 Live |
| `treanding.dart` | Trending + news | Alpha Vantage | 🔌 Live |
| `wishlist.dart` | Saved stocks | SharedPreferences | 🔧 Local |
| `alerts.dart` | Price alerts | Local state | ⚠️ Static |
| `newsmail.dart` | News feed | Alpha Vantage | 🔌 Live |
| `simulator.dart` | Paper simulator | Alpaca bars | 🔌 Live |
| `profile.dart` | User profile | SharedPreferences | 🔧 Local |
| `buy.dart` / `sell.dart` | Trade execution | Alpaca orders | 🔌 Live |
| `order.dart` | Order history | Alpaca orders | 🔌 Live |
| `security_screen.dart` | Biometric + PIN | local_auth + secure_storage | 🔐 Secure |
| `two_factor.dart` | 2FA | Local | 🔐 Secure |
| `notification.dart` | Push alerts | Local state | ⚠️ Static |

**Legend:** 🔌 Live API &nbsp; ⚠️ Static data &nbsp; 🔧 Local storage &nbsp; 🔐 Secure

---

## 🔄 Static Data Migration Guide

When you connect a screen to the backend, follow this pattern:

```dart
// BEFORE (static list in widget)
final List<Map<String,dynamic>> holdings = [
  {'symbol':'AAPL', 'value': 1500.00},
  // ...
];

// AFTER (backend call via service)
import 'package:test_project/core/core.dart';

Future<void> _loadHoldings() async {
  final data = await BackendService.getPortfolio(userId);
  setState(() => holdings = data);
}
```

**Checklist — tick each as you migrate:**

- [ ] `treanding.dart` — `popularStocks` list → `GET /api/stocks/popular`
- [ ] `treanding.dart` — `GainersLosersSection` dummy data → `GET /api/market/movers`
- [ ] `portfolio.dart` — holdings dummy list → `GET /api/portfolio/:id`
- [ ] `wishlist.dart` — watchlist items → `GET /api/wishlist/:id`
- [ ] `alerts.dart` — alerts list → `GET /api/alerts/:id`
- [ ] `screener.dart` — fallback stocks → already using Alpaca, expand filters
- [ ] `simulator.dart` — leaderboard list → `GET /api/leaderboard`
- [ ] `notification.dart` — notification list → `GET /api/notifications/:id`
- [ ] Custom strategies → `POST /api/screener/strategies` (persist on save)

---

## 🔐 Security Architecture

```
lib/features/security/
├── app_lock_wrapper.dart       ← Wraps MaterialApp; gates access behind PIN/bio
├── biometric_service.dart      ← local_auth wrapper (fingerprint / face)
├── secure_storage_service.dart ← flutter_secure_storage wrapper for tokens/PIN
├── pin_lock_screen.dart        ← 4-digit PIN entry UI
├── set_pin_screen.dart         ← First-time PIN setup
├── security_screen.dart        ← Security settings page
├── security_settings_tile.dart ← Reusable settings row widget
└── two_factor.dart             ← 2FA setup and verification
```

**DO NOT** store passwords or API secrets in SharedPreferences.  
Use `SecureStorageService` (flutter_secure_storage) for anything sensitive.

---

## 🖥️ Backend Integration (AlphaCues Infrastructure)

### Microservices Stack
- **Languages:** Kotlin & Java (Spring Boot)
- **Primary Data:** MySQL 8.4 (User records, metadata)
- **Time-Series:** TimescaleDB (Portfolio history, market aggregates)
- **Distributed Cache:** Redis (separate instances for Auth, User, Rate-Limit)
- **Streaming:** Kafka & RabbitMQ
- **Tracing:** Zipkin (Endpoint: `:3390`)
- **Cloud Storage:** Minio (Object storage for static blobs)

### Local Development Setup
1. Clone the API repo: `https://github.com/AlphaCues-org/alphacues-api`
2. Navigate to `michorservice/docker/`
3. Spin up infrastructure:
   ```bash
   docker-compose up -d
   ```
4. Run individual microservices via Gradle:
   ```bash
   ./gradlew bootRun
   ```

> ⚠️ Ensure `lib/core/config/env.dart` points its `backendBase` to the API Gateway IP (usually `10.0.2.2` for Android Emulator or `localhost` for iOS Simulator).

---

## 🚀 Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Run on specific device
flutter run -d android
flutter run -d ios

# Build release APK
flutter build apk --release
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `http` | All REST API calls |
| `fl_chart` | Line / bar / pie charts |
| `candlesticks` | OHLCV candlestick chart |
| `interactive_chart` | Zoomable candlestick chart |
| `intl` | Date/currency formatting |
| `shared_preferences` | Lightweight key-value storage |
| `flutter_secure_storage` | Encrypted storage (tokens, PIN) |
| `local_auth` | Biometric / fingerprint auth |
| `lottie` | JSON animation (loader, success) |
| `image_picker` | Profile photo picker |
| `web_socket_channel` | Real-time price streaming |
| `cached_network_image` | Efficient network image loading |
| `share_plus` | Share reports/screenshots |
| `url_launcher` | Open news articles in browser |
| `fluttertoast` | Toast notifications |
| `postgres` | PostgreSQL driver (backend only) |

---

## 👨‍💻 Contributor Notes

- **New API?** → Add constant to `lib/core/config/env.dart`
- **New HTTP call?** → Add method to the matching service in `lib/core/services/`
- **New data type?** → Add model to `lib/core/models/`
- **Static list → API?** → Follow the Migration Guide above and tick the checklist
- **Design token?** → Use `AppColors`, `AppSpacing`, `AppTextStyles` from `app_constants.dart`

---

*Last updated: February 2026*