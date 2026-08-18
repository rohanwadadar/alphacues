// ============================================================
//  stock_model.dart  —  Stock / Asset data models
// ============================================================

class StockAsset {
  final String symbol;
  final String name;
  final String exchange;
  final double? price;
  final double? change;
  final double? changePercent;
  final double? volume;

  const StockAsset({
    required this.symbol,
    required this.name,
    this.exchange = 'NASDAQ',
    this.price,
    this.change,
    this.changePercent,
    this.volume,
  });

  factory StockAsset.fromAlpaca(Map<String, dynamic> json) => StockAsset(
        symbol  : json['symbol'] as String,
        name    : json['name'] as String,
        exchange: json['exchange'] as String? ?? 'NASDAQ',
      );

  factory StockAsset.fromSnapshot(
      String symbol, Map<String, dynamic> snapshot) {
    final latestTrade = snapshot['latestTrade'] as Map<String, dynamic>? ?? {};
    final dailyBar   = snapshot['dailyBar']   as Map<String, dynamic>? ?? {};
    final prevClose  = snapshot['prevDailyBar']?['c'] as double? ?? 0;
    final price      = (latestTrade['p'] as num?)?.toDouble() ?? 0;
    final change     = price - prevClose;
    final changePct  = prevClose > 0 ? (change / prevClose) * 100 : 0.0;

    return StockAsset(
      symbol       : symbol,
      name         : symbol,
      price        : price,
      change       : change,
      changePercent: changePct,
      volume       : (dailyBar['v'] as num?)?.toDouble(),
    );
  }

  bool get isPositive => (changePercent ?? 0) >= 0;

  @override
  String toString() => 'StockAsset($symbol @ $price)';
}
