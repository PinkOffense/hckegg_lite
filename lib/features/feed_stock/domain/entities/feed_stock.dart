import 'package:equatable/equatable.dart';

enum FeedType {
  layer,
  grower,
  starter,
  scratch,
  supplement,
  other;

  String displayName(String locale) {
    switch (this) {
      case FeedType.layer:
        return locale == 'pt' ? 'Ração Poedeiras' : 'Layer Feed';
      case FeedType.grower:
        return locale == 'pt' ? 'Ração Crescimento' : 'Grower Feed';
      case FeedType.starter:
        return locale == 'pt' ? 'Ração Inicial' : 'Starter Feed';
      case FeedType.scratch:
        return locale == 'pt' ? 'Milho/Cereais' : 'Scratch/Grains';
      case FeedType.supplement:
        return locale == 'pt' ? 'Suplementos' : 'Supplements';
      case FeedType.other:
        return locale == 'pt' ? 'Outro' : 'Other';
    }
  }

  String get icon {
    switch (this) {
      case FeedType.layer: return '🥚';
      case FeedType.grower: return '🌱';
      case FeedType.starter: return '🐣';
      case FeedType.scratch: return '🌽';
      case FeedType.supplement: return '💊';
      case FeedType.other: return '📦';
    }
  }
}

enum StockMovementType {
  purchase,
  consumption,
  adjustment,
  loss;

  String displayName(String locale) {
    switch (this) {
      case StockMovementType.purchase:
        return locale == 'pt' ? 'Compra' : 'Purchase';
      case StockMovementType.consumption:
        return locale == 'pt' ? 'Consumo' : 'Consumption';
      case StockMovementType.adjustment:
        return locale == 'pt' ? 'Ajuste' : 'Adjustment';
      case StockMovementType.loss:
        return locale == 'pt' ? 'Perda' : 'Loss';
    }
  }
}

class FeedStock extends Equatable {
  final String id;
  final FeedType type;
  final String? brand;
  final double currentQuantityKg;
  final double minimumQuantityKg;
  final double? pricePerKg;
  final String? notes;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const FeedStock({
    required this.id,
    required this.type,
    this.brand,
    required this.currentQuantityKg,
    this.minimumQuantityKg = 10.0,
    this.pricePerKg,
    this.notes,
    required this.lastUpdated,
    required this.createdAt,
  });

  bool get isLowStock => currentQuantityKg <= minimumQuantityKg;

  FeedStock copyWith({
    String? id,
    FeedType? type,
    String? brand,
    double? currentQuantityKg,
    double? minimumQuantityKg,
    double? pricePerKg,
    String? notes,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return FeedStock(
      id: id ?? this.id,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      currentQuantityKg: currentQuantityKg ?? this.currentQuantityKg,
      minimumQuantityKg: minimumQuantityKg ?? this.minimumQuantityKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, type, brand, currentQuantityKg, minimumQuantityKg,
        pricePerKg, notes, lastUpdated, createdAt,
      ];
}

class FeedMovement extends Equatable {
  final String id;
  final String feedStockId;
  final StockMovementType movementType;
  final double quantityKg;
  final double? cost;
  final String date;
  final String? notes;
  final DateTime createdAt;

  const FeedMovement({
    required this.id,
    required this.feedStockId,
    required this.movementType,
    required this.quantityKg,
    this.cost,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id, feedStockId, movementType, quantityKg, cost, date, notes, createdAt,
      ];
}
