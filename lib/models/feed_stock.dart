// lib/models/feed_stock.dart

enum FeedType {
  layer,      // Ração para poedeiras
  grower,     // Ração de crescimento
  starter,    // Ração inicial
  scratch,    // Milho/cereais
  supplement, // Suplementos
  other,
}

extension FeedTypeExtension on FeedType {
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
      case FeedType.layer:
        return '🥚';
      case FeedType.grower:
        return '🌱';
      case FeedType.starter:
        return '🐣';
      case FeedType.scratch:
        return '🌽';
      case FeedType.supplement:
        return '💊';
      case FeedType.other:
        return '📦';
    }
  }
}

enum StockMovementType {
  purchase,   // Compra
  consumption,// Consumo
  adjustment, // Ajuste de inventário
  loss,       // Perda/desperdício
}

extension StockMovementTypeExtension on StockMovementType {
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

class FeedStock {
  final String id;
  final FeedType type;
  final String? brand;
  final double currentQuantityKg;
  final double minimumQuantityKg; // Alerta quando abaixo deste valor
  final double? pricePerKg;
  final String? notes;
  final DateTime lastUpdated;
  final DateTime createdAt;

  FeedStock({
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'brand': brand,
      'current_quantity_kg': currentQuantityKg,
      'minimum_quantity_kg': minimumQuantityKg,
      'price_per_kg': pricePerKg,
      'notes': notes,
      'last_updated': lastUpdated.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedStock.fromJson(Map<String, dynamic> json) {
    return FeedStock(
      id: json['id'] as String,
      type: FeedType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedType.other,
      ),
      brand: json['brand'] as String?,
      currentQuantityKg: (json['current_quantity_kg'] as num).toDouble(),
      minimumQuantityKg: (json['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0,
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

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
}

class FeedMovement {
  final String id;
  final String feedStockId;
  final StockMovementType movementType;
  final double quantityKg;
  final double? cost;
  final String date;
  final String? notes;
  final DateTime createdAt;

  FeedMovement({
    required this.id,
    required this.feedStockId,
    required this.movementType,
    required this.quantityKg,
    this.cost,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feed_stock_id': feedStockId,
      'movement_type': movementType.name,
      'quantity_kg': quantityKg,
      'cost': cost,
      'date': date,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedMovement.fromJson(Map<String, dynamic> json) {
    return FeedMovement(
      id: json['id'] as String,
      feedStockId: json['feed_stock_id'] as String,
      movementType: StockMovementType.values.firstWhere(
        (e) => e.name == json['movement_type'],
        orElse: () => StockMovementType.adjustment,
      ),
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
      date: json['date'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
