// ============================================================
//  alpha_vantage_service.dart  —  Alpha Vantage API service
// ============================================================
//  Handles:
//    • News sentiment feed       (Trending, Stock Details)
//    • Symbol search             (Trending search bar)
//    • Daily time series (OHLCV) (Stock Details chart)
//    • Earnings / EPS            (Stock Details fundamentals)
//
//  All endpoints read from Env — no URLs hardcoded here.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class AlphaVantageService {
  // ── News Sentiment ────────────────────────────────────────
  /// Fetches market news with sentiment score.
  /// Used by: Trending news section, Stock Details news feed
  /// ← STATIC: newsmail.dart currently shows a static fallback
  ///            when API quota is exhausted.
  static Future<List<Map<String, dynamic>>> getNews({
    String tickers = 'AAPL',
    int limit = 20,
  }) async {
    try {
      final url = Env.alphaNews(tickers: tickers, limit: limit);
      final response = await http
          .get(Uri.parse(url))
          .timeout(Env.httpTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feed = data['feed'] as List<dynamic>? ?? [];
        return feed.map<Map<String, dynamic>>((item) => {
              'title'    : item['title'] ?? '',
              'summary'  : item['summary'] ?? '',
              'url'      : item['url'] ?? '',
              'source'   : item['source'] ?? '',
              'sentiment': item['overall_sentiment_score'] ?? 0.0,
              'label'    : item['overall_sentiment_label'] ?? 'Neutral',
              'publishedAt': item['time_published'] ?? '',
              'bannerImage': item['banner_image'] ?? '',
            }).toList();
      }
    } catch (e) {
      print('[AlphaVantageService.getNews] $e');
    }
    return [];
  }

  // ── Symbol Search ─────────────────────────────────────────
  /// Searches stocks by keyword (name or ticker).
  /// Used by: Trending search bar
  static Future<List<Map<String, dynamic>>> searchSymbol(
      String keywords) async {
    if (keywords.trim().isEmpty) return [];
    try {
      final url = Env.alphaSymbolSearch(keywords);
      final response = await http
          .get(Uri.parse(url))
          .timeout(Env.httpTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['bestMatches'] as List<dynamic>? ?? [];
        return matches.map<Map<String, dynamic>>((m) => {
              'symbol'  : m['1. symbol'] ?? '',
              'name'    : m['2. name'] ?? '',
              'region'  : m['4. region'] ?? '',
              'currency': m['8. currency'] ?? 'USD',
            }).toList();
      }
    } catch (e) {
      print('[AlphaVantageService.searchSymbol] $e');
    }
    return [];
  }

  // ── Daily Time Series (OHLCV) ─────────────────────────────
  /// Returns daily close prices for a stock symbol.
  /// Used by: Stock Details price chart, Simulator
  static Future<Map<String, Map<String, dynamic>>> getTimeSeries(
      String symbol) async {
    try {
      final url = Env.alphaTimeSeries(symbol);
      final response = await http
          .get(Uri.parse(url))
          .timeout(Env.httpTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final series =
            data['Time Series (Daily)'] as Map<String, dynamic>? ?? {};
        return series.map((date, values) => MapEntry(
              date,
              {
                'open'  : double.tryParse(values['1. open']  ?? '0') ?? 0,
                'high'  : double.tryParse(values['2. high']  ?? '0') ?? 0,
                'low'   : double.tryParse(values['3. low']   ?? '0') ?? 0,
                'close' : double.tryParse(values['4. close'] ?? '0') ?? 0,
                'volume': double.tryParse(values['5. volume'] ?? '0') ?? 0,
              },
            ));
      }
    } catch (e) {
      print('[AlphaVantageService.getTimeSeries] $e');
    }
    return {};
  }

  // ── Earnings ──────────────────────────────────────────────
  /// Returns quarterly EPS data for a stock.
  /// Used by: Stock Details fundamentals section
  static Future<List<Map<String, dynamic>>> getEarnings(
      String symbol) async {
    try {
      final url = Env.alphaEarnings(symbol);
      final response = await http
          .get(Uri.parse(url))
          .timeout(Env.httpTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quarterly =
            data['quarterlyEarnings'] as List<dynamic>? ?? [];
        return quarterly.map<Map<String, dynamic>>((q) => {
              'date'           : q['fiscalDateEnding'] ?? '',
              'reportedEPS'    : q['reportedEPS'] ?? '0',
              'estimatedEPS'   : q['estimatedEPS'] ?? '0',
              'surprise'       : q['surprise'] ?? '0',
              'surprisePercent': q['surprisePercentage'] ?? '0',
            }).toList();
      }
    } catch (e) {
      print('[AlphaVantageService.getEarnings] $e');
    }
    return [];
  }
}
