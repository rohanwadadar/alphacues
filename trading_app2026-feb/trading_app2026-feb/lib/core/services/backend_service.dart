// ============================================================
//  backend_service.dart  —  Custom backend REST service
// ============================================================
//  Thin client for the app's own Node/Express backend.
//  Most methods are stubs (marked ← TODO) because the REST
//  layer does not exist yet — data is served statically.
//
//  Workflow when adding a new backend route:
//    1. Add endpoint constant/helper to Env
//    2. Implement the method body here
//    3. Replace the static list in the relevant screen
//    4. Tick off the checklist in env.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class BackendService {
  static final Map<String, String> _headers = {
    'content-type': 'application/json',
    'accept'      : 'application/json',
    // TODO: Add Bearer token once auth is implemented
    // 'Authorization': 'Bearer $token',
  };

  // ── User Profile ──────────────────────────────────────────
  /// ← TODO: implement when /api/users/:id is ready
  /// Currently: profile.dart uses SharedPreferences + static
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendUser(userId)), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('[BackendService.getUser] $e');
    }
    return null;
  }

  // ── Portfolio ─────────────────────────────────────────────
  /// ← TODO: implement when /api/portfolio/:id is ready
  /// Currently: portfolio.dart shows hardcoded holdings
  static Future<List<Map<String, dynamic>>> getPortfolio(
      String userId) async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendPortfolio(userId)), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[BackendService.getPortfolio] $e');
    }
    return [];
  }

  // ── Transactions ──────────────────────────────────────────
  /// ← TODO: implement when /api/transactions/:id is ready
  /// Currently: order.dart shows hardcoded order list
  static Future<List<Map<String, dynamic>>> getTransactions(
      String userId) async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendTransactions(userId)), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[BackendService.getTransactions] $e');
    }
    return [];
  }

  // ── Wishlist ──────────────────────────────────────────────
  /// ← TODO: implement when /api/wishlist is ready
  /// Currently: wishlist.dart uses SharedPreferences
  static Future<List<String>> getWishlist(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('${Env.backendWishlist}/$userId'),
              headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print('[BackendService.getWishlist] $e');
    }
    return [];
  }

  static Future<bool> toggleWishlist(
      String userId, String symbol, bool add) async {
    try {
      final body = json.encode({'userId': userId, 'symbol': symbol});
      final response = add
          ? await http.post(Uri.parse(Env.backendWishlist),
              headers: _headers, body: body)
          : await http.delete(Uri.parse('${Env.backendWishlist}/$symbol'),
              headers: _headers);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[BackendService.toggleWishlist] $e');
      return false;
    }
  }

  // ── Alerts ────────────────────────────────────────────────
  /// ← TODO: implement when /api/alerts is ready
  /// Currently: alerts.dart uses a local in-memory list
  static Future<List<Map<String, dynamic>>> getAlerts(String userId) async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendAlerts(userId)), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[BackendService.getAlerts] $e');
    }
    return [];
  }

  // ── Screener Strategies ───────────────────────────────────
  /// ← TODO: implement when /api/screener/strategies is ready
  /// Currently: strategies live in Trending screen state
  static Future<List<Map<String, dynamic>>> getStrategies(
      String userId) async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendStrategies(userId)), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[BackendService.getStrategies] $e');
    }
    return [];
  }

  static Future<bool> saveStrategy(Map<String, dynamic> strategy) async {
    try {
      final response = await http
          .post(Uri.parse(Env.backendSaveStrategy),
              headers: _headers, body: json.encode(strategy))
          .timeout(Env.httpTimeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[BackendService.saveStrategy] $e');
      return false;
    }
  }

  static Future<bool> deleteStrategy(String id) async {
    try {
      final response = await http
          .delete(Uri.parse(Env.backendDeleteStrategy(id)),
              headers: _headers)
          .timeout(Env.httpTimeout);
      return response.statusCode == 200;
    } catch (e) {
      print('[BackendService.deleteStrategy] $e');
      return false;
    }
  }

  // ── News ──────────────────────────────────────────────────
  /// ← TODO: implement when /api/news (curated feed) is ready
  static Future<List<Map<String, dynamic>>> getNews() async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendNews), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[BackendService.getNews] $e');
    }
    return [];
  }

  // ── Simulator Leaderboard ─────────────────────────────────
  /// ← TODO: implement when /api/simulator/leaderboard is ready
  /// Currently: simulator.dart has a static top-10 list
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await http
          .get(Uri.parse(Env.backendLeaderboard), headers: _headers)
          .timeout(Env.httpTimeout);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('[BackendService.getLeaderboard] $e');
    }
    return [];
  }
}
