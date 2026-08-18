// ============================================================
//  alpaca_service.dart  —  Alpaca Markets API service
// ============================================================
//  Handles all HTTP communication with Alpaca:
//    • Asset listing   (Screener)
//    • Orders          (Buy / Sell / Order History)
//    • Positions       (Portfolio holdings)
//    • Account info    (Balance / Buying power)
//    • OHLCV bars      (Chart / Simulator)
//    • Snapshots       (Real-time quotes)
//
//  All endpoints read from Env — no URLs hardcoded here.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class AlpacaService {
  // ── Assets ────────────────────────────────────────────────
  /// Returns tradable US equity assets.
  /// Used by: Screener screen
  static Future<List<Map<String, dynamic>>> getActiveAssets() async {
    try {
      final response = await http
          .get(Uri.parse(Env.alpacaAssets()), headers: Env.alpacaHeaders)
          .timeout(Env.httpTimeout);

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return list
            .where((a) => a['tradable'] == true && a['status'] == 'active')
            .take(Env.screenerLimit)
            .map<Map<String, dynamic>>((a) => {
                  'symbol'  : a['symbol'],
                  'name'    : a['name'] ?? a['symbol'],
                  'exchange': a['exchange'] ?? 'NASDAQ',
                })
            .toList();
      }
    } catch (e) {
      // TODO: replace with proper logging service
      print('[AlpacaService.getActiveAssets] $e');
    }
    return _fallbackStocks();
  }

  // ── Portfolio / Positions ─────────────────────────────────
  /// Returns the current open positions.
  /// Used by: Portfolio screen
  /// ← STATIC: Portfolio screen uses a hardcoded list for now.
  ///            Replace with this call when backend is ready.
  static Future<List<Map<String, dynamic>>> getPositions() async {
    try {
      final response = await http
          .get(Uri.parse(Env.alpacaPositions), headers: Env.alpacaHeaders)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[AlpacaService.getPositions] $e');
    }
    return [];
  }

  // ── Account ───────────────────────────────────────────────
  /// Returns account equity, buying power, cash balance.
  /// Used by: Dashboard, Portfolio header
  /// ← STATIC: Currently shown as static figures in portfolio.dart
  static Future<Map<String, dynamic>?> getAccount() async {
    try {
      final response = await http
          .get(Uri.parse(Env.alpacaAccount), headers: Env.alpacaHeaders)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('[AlpacaService.getAccount] $e');
    }
    return null;
  }

  // ── Orders ────────────────────────────────────────────────
  /// Returns order history (open + closed).
  /// Used by: Order screen
  /// ← STATIC: order.dart has a hardcoded list currently.
  static Future<List<Map<String, dynamic>>> getOrders({
    String status = 'all',
  }) async {
    try {
      final url = '${Env.alpacaOrders}?status=$status&limit=${Env.defaultPageSize}';
      final response = await http
          .get(Uri.parse(url), headers: Env.alpacaHeaders)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[AlpacaService.getOrders] $e');
    }
    return [];
  }

  /// Place a market or limit order.
  /// Used by: Buy screen, Sell screen
  static Future<bool> placeOrder({
    required String symbol,
    required String side,   // 'buy' or 'sell'
    required String qty,
    String type    = 'market',
    String timeInForce = 'day',
  }) async {
    try {
      final body = json.encode({
        'symbol'        : symbol,
        'qty'           : qty,
        'side'          : side,
        'type'          : type,
        'time_in_force' : timeInForce,
      });
      final response = await http
          .post(Uri.parse(Env.alpacaPlaceOrder),
              headers: Env.alpacaHeaders, body: body)
          .timeout(Env.httpTimeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[AlpacaService.placeOrder] $e');
      return false;
    }
  }

  // ── OHLCV Bars ───────────────────────────────────────────
  /// Returns candlestick data for a symbol.
  /// Used by: Stock Details chart, Simulator
  static Future<List<Map<String, dynamic>>> getBars(
    String symbol, {
    String timeframe = '1Day',
    int limit = 100,
  }) async {
    try {
      final url = Env.alpacaBars(symbol, timeframe: timeframe, limit: limit);
      final response = await http
          .get(Uri.parse(url), headers: Env.alpacaHeaders)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bars = data['bars']?[symbol] as List<dynamic>? ?? [];
        return bars.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('[AlpacaService.getBars] $e');
    }
    return [];
  }

  // ── Snapshots ────────────────────────────────────────────
  /// Returns latest quote/trade for multiple symbols at once.
  /// Used by: Stock list, Trending, Screener results
  static Future<Map<String, dynamic>> getSnapshots(
      List<String> symbols) async {
    try {
      final url = Env.alpacaSnapshots(symbols);
      final response = await http
          .get(Uri.parse(url), headers: Env.alpacaHeaders)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('[AlpacaService.getSnapshots] $e');
    }
    return {};
  }

  // ── Fallback data (used while backend is not connected) ──
  /// ← STATIC: remove once screener fully uses live Alpaca data
  static List<Map<String, dynamic>> _fallbackStocks() => [
        {'symbol': 'TSLA', 'name': 'Tesla Inc',             'exchange': 'NASDAQ'},
        {'symbol': 'AVGO', 'name': 'Broadcom Inc',          'exchange': 'NASDAQ'},
        {'symbol': 'NVDA', 'name': 'NVIDIA Corporation',    'exchange': 'NASDAQ'},
        {'symbol': 'META', 'name': 'Meta Platforms',        'exchange': 'NASDAQ'},
        {'symbol': 'AMD',  'name': 'Advanced Micro Devices','exchange': 'NASDAQ'},
        {'symbol': 'MU',   'name': 'Micron Technology',     'exchange': 'NASDAQ'},
        {'symbol': 'AAPL', 'name': 'Apple Inc',             'exchange': 'NASDAQ'},
        {'symbol': 'AMZN', 'name': 'Amazon.com Inc',        'exchange': 'NASDAQ'},
        {'symbol': 'GOOGL','name': 'Alphabet Inc',          'exchange': 'NASDAQ'},
        {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'exchange': 'NASDAQ'},
      ];
}
