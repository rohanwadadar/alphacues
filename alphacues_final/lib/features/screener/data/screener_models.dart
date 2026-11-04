// Screener domain models.
// Filter field names match the closed enum the Task 18 backend defines in
// ScreenerFilterSchema (schemas.py):
//   marketCapMin/Max, peRatioMin/Max, priceMin/Max,
//   changePercentMin/Max, dividendYieldMin, exchange
//
// Sort fields (VALID_SORT_FIELDS):  marketCap | peRatio | price | changePercent | symbol
// Sort orders (VALID_SORT_ORDERS):  asc | desc

class ScreenerFilter {
  const ScreenerFilter({
    this.marketCapMin,
    this.marketCapMax,
    this.peRatioMin,
    this.peRatioMax,
    this.priceMin,
    this.priceMax,
    this.changePercentMin,
    this.changePercentMax,
    this.dividendYieldMin,
    this.exchange,
  });

  final double? marketCapMin;
  final double? marketCapMax;
  final double? peRatioMin;
  final double? peRatioMax;
  final double? priceMin;
  final double? priceMax;
  final double? changePercentMin;
  final double? changePercentMax;
  final double? dividendYieldMin;
  final String? exchange;

  bool get isEmpty =>
      marketCapMin == null &&
      marketCapMax == null &&
      peRatioMin == null &&
      peRatioMax == null &&
      priceMin == null &&
      priceMax == null &&
      changePercentMin == null &&
      changePercentMax == null &&
      dividendYieldMin == null &&
      (exchange == null || exchange!.isEmpty);

  ScreenerFilter copyWith({
    double? marketCapMin,
    double? marketCapMax,
    double? peRatioMin,
    double? peRatioMax,
    double? priceMin,
    double? priceMax,
    double? changePercentMin,
    double? changePercentMax,
    double? dividendYieldMin,
    String? exchange,
  }) {
    return ScreenerFilter(
      marketCapMin: marketCapMin ?? this.marketCapMin,
      marketCapMax: marketCapMax ?? this.marketCapMax,
      peRatioMin: peRatioMin ?? this.peRatioMin,
      peRatioMax: peRatioMax ?? this.peRatioMax,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      changePercentMin: changePercentMin ?? this.changePercentMin,
      changePercentMax: changePercentMax ?? this.changePercentMax,
      dividendYieldMin: dividendYieldMin ?? this.dividendYieldMin,
      exchange: exchange ?? this.exchange,
    );
  }

  /// Serialises only non-null fields so backend ignores unset filters.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (marketCapMin != null) map['marketCapMin'] = marketCapMin;
    if (marketCapMax != null) map['marketCapMax'] = marketCapMax;
    if (peRatioMin != null) map['peRatioMin'] = peRatioMin;
    if (peRatioMax != null) map['peRatioMax'] = peRatioMax;
    if (priceMin != null) map['priceMin'] = priceMin;
    if (priceMax != null) map['priceMax'] = priceMax;
    if (changePercentMin != null) map['changePercentMin'] = changePercentMin;
    if (changePercentMax != null) map['changePercentMax'] = changePercentMax;
    if (dividendYieldMin != null) map['dividendYieldMin'] = dividendYieldMin;
    if (exchange != null && exchange!.isNotEmpty) map['exchange'] = exchange;
    return map;
  }

  factory ScreenerFilter.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScreenerFilter();
    return ScreenerFilter(
      marketCapMin: (json['marketCapMin'] as num?)?.toDouble(),
      marketCapMax: (json['marketCapMax'] as num?)?.toDouble(),
      peRatioMin: (json['peRatioMin'] as num?)?.toDouble(),
      peRatioMax: (json['peRatioMax'] as num?)?.toDouble(),
      priceMin: (json['priceMin'] as num?)?.toDouble(),
      priceMax: (json['priceMax'] as num?)?.toDouble(),
      changePercentMin: (json['changePercentMin'] as num?)?.toDouble(),
      changePercentMax: (json['changePercentMax'] as num?)?.toDouble(),
      dividendYieldMin: (json['dividendYieldMin'] as num?)?.toDouble(),
      exchange: json['exchange'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Result item — matches fields returned by ScreenerService.run_scan()
// ---------------------------------------------------------------------------
class ScreenerResultItem {
  const ScreenerResultItem({
    required this.symbol,
    required this.name,
    required this.marketCap,
    this.peRatio,
    this.eps,
    this.dividendYield,
    required this.fiftyTwoWeekHigh,
    required this.fiftyTwoWeekLow,
    required this.price,
    required this.changePercent,
    required this.changeAmount,
    required this.exchange,
  });

  final String symbol;
  final String name;
  final double? marketCap;
  final double? peRatio;
  final double? eps;
  final double? dividendYield;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final double price;
  final double changePercent;
  final double changeAmount;
  final String? exchange;

  factory ScreenerResultItem.fromJson(Map<String, dynamic> json) {
    return ScreenerResultItem(
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      peRatio: (json['peRatio'] as num?)?.toDouble(),
      eps: (json['eps'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      fiftyTwoWeekHigh: (json['fiftyTwoWeekHigh'] as num?)?.toDouble(),
      fiftyTwoWeekLow: (json['fiftyTwoWeekLow'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0.0,
      exchange: json['exchange'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Scan result — { total, limit, items }
// ---------------------------------------------------------------------------
class ScreenerScanResult {
  const ScreenerScanResult({
    required this.total,
    required this.limit,
    required this.items,
  });

  final int total;
  final int limit;
  final List<ScreenerResultItem> items;

  factory ScreenerScanResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ScreenerScanResult(
      total: json['total'] as int? ?? rawItems.length,
      limit: json['limit'] as int? ?? 50,
      items: rawItems
          .map((e) => ScreenerResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Strategy — matches ScreenerService.strategy_to_dict() output:
//   strategyId, userId, name, description, filters, sortBy, sortOrder,
//   createdAt, updatedAt
// ---------------------------------------------------------------------------
class ScreenerStrategy {
  const ScreenerStrategy({
    required this.strategyId,
    required this.name,
    this.description,
    required this.filters,
    required this.sortBy,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final int strategyId;
  final String name;
  final String? description;
  final ScreenerFilter filters;
  final String sortBy;
  final String sortOrder;
  final String? createdAt;
  final String? updatedAt;

  factory ScreenerStrategy.fromJson(Map<String, dynamic> json) {
    return ScreenerStrategy(
      strategyId: json['strategyId'] is int
          ? json['strategyId'] as int
          : int.parse(json['strategyId'].toString()),
      name: json['name'] as String? ?? 'Strategy',
      description: json['description'] as String?,
      filters: ScreenerFilter.fromJson(
        json['filters'] as Map<String, dynamic>?,
      ),
      sortBy: json['sortBy'] as String? ?? 'changePercent',
      sortOrder: json['sortOrder'] as String? ?? 'desc',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Paginated list result — carries strategies + nextCursor from meta
// ---------------------------------------------------------------------------
class ScreenerStrategyListResult {
  const ScreenerStrategyListResult({
    required this.strategies,
    this.nextCursor,
  });

  final List<ScreenerStrategy> strategies;
  final String? nextCursor;
}
