// ============================================================
//  strategy_model.dart  —  Screener strategy data model
// ============================================================

class ScreenerStrategy {
  final String id;           // uuid — assigned by backend when persisted
  final String name;
  final bool   isCustom;
  final Map<String, dynamic> filters;
  final DateTime createdAt;

  const ScreenerStrategy({
    required this.id,
    required this.name,
    required this.isCustom,
    required this.filters,
    required this.createdAt,
  });

  factory ScreenerStrategy.fromMap(Map<String, dynamic> map) =>
      ScreenerStrategy(
        id       : map['id']?.toString()    ?? '',
        name     : map['name'] as String,
        isCustom : map['isCustom'] as bool? ?? true,
        filters  : Map<String, dynamic>.from(
            map['filters'] as Map<String, dynamic>? ?? {}),
        createdAt: map['createdAt'] is DateTime
            ? map['createdAt'] as DateTime
            : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id'       : id,
        'name'     : name,
        'isCustom' : isCustom,
        'filters'  : filters,
        'createdAt': createdAt.toIso8601String(),
      };
}
