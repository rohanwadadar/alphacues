// ============================================================
//  env.dart  —  Central Environment & API Configuration
// ============================================================
//
//  PURPOSE:
//    Single source of truth for every URL, API key, and
//    configurable constant used across the app.
//
//  MIGRATION NOTE (for backend integration):
//    Fields marked  ← STATIC  are currently hardcoded lists
//    in the UI. When a real backend is ready, replace the
//    relevant service call with an HTTP request to the
//    matching [Future backend] URL shown in the comments.
//
//  SECURITY NOTE:
//    In production, load sensitive keys from a secure store
//    (e.g. flutter_dotenv + CI/CD secrets) instead of
//    hardcoding here.
//
// ============================================================

class Env {
  Env._(); // prevent instantiation

  // ----------------------------------------------------------
  // 🔧  APP SETTINGS
  // ----------------------------------------------------------
  static const String appName        = 'TradeApp 2026';
  static const String appVersion     = '1.0.0';
  static const bool   isProduction   = false; // flip to true before release

  // ----------------------------------------------------------
  // 📊  ALPACA MARKETS  (Stock Trading & Asset data)
  //      Docs: https://docs.alpaca.markets/reference
  // ----------------------------------------------------------
  /// Base URL for market data (quotes, bars, snapshots)
  static const String alpacaDataUrl    = 'https://data.alpaca.markets';

  /// Base URL for trading actions (orders, positions, accounts)
  static const String alpacaTradingUrl = 'https://paper-api.alpaca.markets';

  /// Alpaca API key ID  — replace with env var in production
  static const String alpacaKeyId      = 'PK6O4W6SBWAVCTZKQRPC';

  /// Alpaca API secret  — replace with env var in production
  static const String alpacaSecret     = 'e1rimphcUKc7SmJv9N3gla0oiMPgP8sstxp0Vk7D';

  /// Pre-built auth headers for every Alpaca request
  static Map<String, String> get alpacaHeaders => {
    'APCA-API-KEY-ID'    : alpacaKeyId,
    'APCA-API-SECRET-KEY': alpacaSecret,
    'accept'             : 'application/json',
    'content-type'       : 'application/json',
  };

  // Alpaca endpoint helpers
  /// GET  /v2/assets?status=active&asset_class=us_equity
  /// Returns tradable US equity assets (used by Screener)
  static String alpacaAssets({String status = 'active', String assetClass = 'us_equity'}) =>
      '$alpacaTradingUrl/v2/assets?status=$status&asset_class=$assetClass';

  /// GET  /v2/orders
  /// Returns open/closed orders (used by Order screen)
  static const String alpacaOrders     = '$alpacaTradingUrl/v2/orders';

  /// GET  /v2/positions
  /// Returns current portfolio positions
  static const String alpacaPositions  = '$alpacaTradingUrl/v2/positions';

  /// GET  /v2/account
  /// Returns account balance, buying power, equity
  static const String alpacaAccount    = '$alpacaTradingUrl/v2/account';

  /// POST /v2/orders  — place a buy/sell market or limit order
  static const String alpacaPlaceOrder = '$alpacaTradingUrl/v2/orders';

  /// GET  /v2/bars?symbols=AAPL&timeframe=1Day
  /// Returns OHLCV candlestick data (used by Stock Details / Simulator)
  static String alpacaBars(String symbol, {String timeframe = '1Day', int limit = 100}) =>
      '$alpacaDataUrl/v2/stocks/bars?symbols=$symbol&timeframe=$timeframe&limit=$limit&feed=iex';

  /// GET  /v2/stocks/snapshots?symbols=AAPL,TSLA
  /// Returns latest quote + trade for a list of symbols
  static String alpacaSnapshots(List<String> symbols) =>
      '$alpacaDataUrl/v2/stocks/snapshots?symbols=${symbols.join(",")}';

  // ----------------------------------------------------------
  // 📰  ALPHA VANTAGE  (News & financial fundamentals)
  //      Docs: https://www.alphavantage.co/documentation/
  // ----------------------------------------------------------
  static const String alphaVantageBase   = 'https://www.alphavantage.co/query';

  /// Alpha Vantage free-tier API key  — replace with env var
  static const String alphaVantageKey    = 'XH0MOF8FACW6RR0L';

  // Alpha Vantage endpoint helpers
  /// NEWS_SENTIMENT  — market news with sentiment score
  /// Used by: Trending screen, Stock Details news feed
  static String alphaNews({String tickers = 'AAPL', int limit = 20}) =>
      '$alphaVantageBase?function=NEWS_SENTIMENT&tickers=$tickers&apikey=$alphaVantageKey&limit=$limit';

  /// SYMBOL_SEARCH  — search stocks by keyword
  /// Used by: Trending search bar
  static String alphaSymbolSearch(String keywords) =>
      '$alphaVantageBase?function=SYMBOL_SEARCH&keywords=$keywords&apikey=$alphaVantageKey';

  /// TIME_SERIES_DAILY  — daily OHLCV time series for a symbol
  /// Used by: Stock Details chart, Simulator historical data
  static String alphaTimeSeries(String symbol) =>
      '$alphaVantageBase?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$alphaVantageKey';

  /// EARNINGS  — quarterly EPS data
  /// Used by: Stock Details fundamentals
  static String alphaEarnings(String symbol) =>
      '$alphaVantageBase?function=EARNINGS&symbol=$symbol&apikey=$alphaVantageKey';

  // ----------------------------------------------------------
  // 🖥️  ALPHA CUES BACKEND  (Spring Boot Microservices)
  //      Gateway Entry: Port 8080
  //      Suggestion LB: Port 9009 (WebSockets)
  // ----------------------------------------------------------
  static const String backendBase = 'http://localhost:8080/api/v1';

  // ← MIGRATION STATUS: Integration in progress.
  //   The following endpoints are routed via the API Gateway.

  /// GET /api/v1/user/profile/:id
  static String backendUser(String userId)           => '$backendBase/user/profile/$userId';

  /// GET /api/v1/user/portfolio/:userId
  static String backendPortfolio(String userId)      => '$backendBase/user/portfolio/$userId';

  /// GET /api/v1/user/transactions/:userId
  static String backendTransactions(String userId)   => '$backendBase/user/transactions/$userId';

  /// POST /api/v1/user/wishlist
  static const String backendWishlist                = '$backendBase/user/wishlist';

  /// GET /api/v1/user/alerts/:userId
  static String backendAlerts(String userId)         => '$backendBase/user/alerts/$userId';

  /// POST /api/v1/user/alerts
  static const String backendCreateAlert             = '$backendBase/user/alerts';

  /// GET /api/v1/user/screener/strategies/:userId
  static String backendStrategies(String userId)     => '$backendBase/user/screener/strategies/$userId';

  /// POST /api/v1/user/screener/strategies
  static const String backendSaveStrategy            = '$backendBase/user/screener/strategies';

  /// DELETE /api/v1/user/screener/strategies/:id
  static String backendDeleteStrategy(String id)     => '$backendBase/user/screener/strategies/$id';

  /// GET /api/v1/user/news
  static const String backendNews                    = '$backendBase/user/news';

  /// GET /api/v1/user/leaderboard
  static const String backendLeaderboard             = '$backendBase/user/leaderboard';

  /// REAL-TIME: ws://localhost:9009/api/v1/suggestion/
  static const String suggestionWebSocket            = 'ws://localhost:9009/api/v1/suggestion/';

  // ----------------------------------------------------------
  // 🗄️  BACKEND INFRASTRUCTURE (Reference only)
  // ----------------------------------------------------------
  static const String dbMySQLPort     = '3330';
  static const String dbPostgresPort  = '3331';
  static const String redisAuthPort   = '6390';
  static const String redisUserPort   = '6391';
  static const String zipkinPort      = '3390';

  // ----------------------------------------------------------
  // ⏱️  TIMEOUTS & PAGINATION
  // ----------------------------------------------------------
  static const Duration httpTimeout     = Duration(seconds: 15);
  static const int      defaultPageSize = 20;
  static const int      screenerLimit   = 50;
}

// ============================================================
//  STATIC DATA MIGRATION CHECKLIST
//  (comment out each line as you migrate to real API)
// ============================================================
//
//  [ ] treanding.dart   — popularStocks list       → GET /api/stocks/popular
//  [ ] treanding.dart   — newsData static fallback → GET /api/news
//  [ ] trending.dart    — GainersLosers dummy data → GET /api/market/movers
//  [ ] portfolio.dart   — holdings dummy list      → GET /api/portfolio/:id
//  [ ] wishlist.dart    — watchlist items          → GET /api/wishlist/:id
//  [ ] alerts.dart      — alerts list              → GET /api/alerts/:id
//  [ ] screener.dart    — fallback stocks          → GET /api/screener/run
//  [ ] simulator.dart   — leaderboard list         → GET /api/leaderboard
//  [ ] stock.dart       — top gainers/losers       → GET /api/market/movers
//  [ ] notification.dart — notification list       → GET /api/notifications/:id
//
// ============================================================
