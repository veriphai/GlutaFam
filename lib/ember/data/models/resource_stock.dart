// Ember — data/models/resource_stock.dart
//
// The player's stockpile across all ResourceTypes. Each type tracks
// {amount, cap, threshold}. Spend/add are pure (return new ResourceStock).
// canAfford/spend interop with ResourceCost.

import '../../core/constants.dart';
import '../../core/enums.dart';
import 'resource_cost.dart';

/// One resource's storage line.
class StockLine {
  const StockLine({
    required this.amount,
    required this.cap,
    required this.threshold,
  });

  final int amount;
  final int cap;
  final int threshold;

  bool get isLow => amount <= threshold;
  bool get isFull => amount >= cap;
  int get surplus => (amount - threshold).clamp(0, cap);

  StockLine copyWith({int? amount, int? cap, int? threshold}) => StockLine(
        amount: amount ?? this.amount,
        cap: cap ?? this.cap,
        threshold: threshold ?? this.threshold,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amount': amount,
        'cap': cap,
        'threshold': threshold,
      };

  factory StockLine.fromJson(Map<String, dynamic> j) => StockLine(
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        cap: (j['cap'] as num?)?.toInt() ?? EmberConstants.defaultResourceCap,
        threshold: (j['threshold'] as num?)?.toInt() ??
            EmberConstants.defaultResourceThreshold,
      );

  @override
  bool operator ==(Object other) =>
      other is StockLine &&
      other.amount == amount &&
      other.cap == cap &&
      other.threshold == threshold;

  @override
  int get hashCode => Object.hash(amount, cap, threshold);
}

class ResourceStock {
  ResourceStock(Map<ResourceType, StockLine> lines)
      : _lines = Map<ResourceType, StockLine>.unmodifiable(lines);

  /// A fresh stockpile with every type at [start], default caps/thresholds.
  factory ResourceStock.initial({
    int start = 0,
    int cap = EmberConstants.defaultResourceCap,
    int threshold = EmberConstants.defaultResourceThreshold,
    Map<ResourceType, int>? overrides,
  }) {
    return ResourceStock(<ResourceType, StockLine>{
      for (final ResourceType t in ResourceType.values)
        t: StockLine(
          amount: overrides?[t] ?? start,
          cap: cap,
          threshold: threshold,
        ),
    });
  }

  final Map<ResourceType, StockLine> _lines;

  Map<ResourceType, StockLine> get lines => _lines;

  StockLine lineOf(ResourceType t) =>
      _lines[t] ??
      const StockLine(
        amount: 0,
        cap: EmberConstants.defaultResourceCap,
        threshold: EmberConstants.defaultResourceThreshold,
      );

  int amountOf(ResourceType t) => lineOf(t).amount;

  bool canAfford(ResourceCost cost) {
    for (final MapEntry<ResourceType, int> e in cost.amounts.entries) {
      if (amountOf(e.key) < e.value) return false;
    }
    return true;
  }

  /// Returns a NEW stock with [cost] deducted. Caller should canAfford first;
  /// amounts are clamped at 0 to stay well-defined.
  ResourceStock spend(ResourceCost cost) {
    final Map<ResourceType, StockLine> next =
        Map<ResourceType, StockLine>.of(_lines);
    for (final MapEntry<ResourceType, int> e in cost.amounts.entries) {
      final StockLine line = lineOf(e.key);
      next[e.key] =
          line.copyWith(amount: (line.amount - e.value).clamp(0, line.cap));
    }
    return ResourceStock(next);
  }

  /// Adds a single resource (clamped to cap). Returns a new stock.
  ResourceStock add(ResourceType t, int qty) {
    final StockLine line = lineOf(t);
    final Map<ResourceType, StockLine> next =
        Map<ResourceType, StockLine>.of(_lines);
    next[t] = line.copyWith(amount: (line.amount + qty).clamp(0, line.cap));
    return ResourceStock(next);
  }

  /// Adds a whole bundle (each clamped to cap). Returns a new stock.
  ResourceStock addCost(ResourceCost bundle) {
    ResourceStock s = this;
    for (final MapEntry<ResourceType, int> e in bundle.amounts.entries) {
      s = s.add(e.key, e.value);
    }
    return s;
  }

  /// Raises the cap for [t] by [delta] (shelter etc. may grow storage). New stock.
  ResourceStock withCap(ResourceType t, int newCap) {
    final StockLine line = lineOf(t);
    final Map<ResourceType, StockLine> next =
        Map<ResourceType, StockLine>.of(_lines);
    next[t] = line.copyWith(
      cap: newCap,
      amount: line.amount.clamp(0, newCap),
    );
    return ResourceStock(next);
  }

  /// Surplus above threshold for [t].
  int surplus(ResourceType t) => lineOf(t).surplus;

  Map<String, dynamic> toJson() => <String, dynamic>{
        for (final ResourceType t in ResourceType.values)
          t.name: lineOf(t).toJson(),
      };

  factory ResourceStock.fromJson(Map<String, dynamic> j) =>
      ResourceStock(<ResourceType, StockLine>{
        for (final ResourceType t in ResourceType.values)
          t: j[t.name] is Map
              ? StockLine.fromJson((j[t.name] as Map).cast<String, dynamic>())
              : const StockLine(
                  amount: 0,
                  cap: EmberConstants.defaultResourceCap,
                  threshold: EmberConstants.defaultResourceThreshold,
                ),
      });

  @override
  bool operator ==(Object other) {
    if (other is! ResourceStock) return false;
    for (final ResourceType t in ResourceType.values) {
      if (other.lineOf(t) != lineOf(t)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        <Object>[for (final ResourceType t in ResourceType.values) lineOf(t)],
      );
}
