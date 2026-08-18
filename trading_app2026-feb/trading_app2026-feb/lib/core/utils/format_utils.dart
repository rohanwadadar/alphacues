// ============================================================
//  format_utils.dart  —  Common formatting helpers
// ============================================================

import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  // ── Numbers ───────────────────────────────────────────────
  static String currency(double value, {String symbol = '\$'}) =>
      '$symbol${NumberFormat('#,##0.00').format(value.abs())}';

  static String compact(double value) =>
      NumberFormat.compact().format(value);

  static String percent(double value, {int decimals = 2}) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}%';
  }

  static String volume(double vol) {
    if (vol >= 1e9) return '${(vol / 1e9).toStringAsFixed(1)}B';
    if (vol >= 1e6) return '${(vol / 1e6).toStringAsFixed(1)}M';
    if (vol >= 1e3) return '${(vol / 1e3).toStringAsFixed(1)}K';
    return vol.toStringAsFixed(0);
  }

  // ── Dates ─────────────────────────────────────────────────
  static String dateShort(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours  < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Stock symbol logo URL (Clearbit fallback) ─────────────
  static String logoUrl(String symbol) =>
      'https://assets.coincap.io/assets/icons/'
      '${symbol.toLowerCase()}@2x.png';
}
