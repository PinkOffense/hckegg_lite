import '../../domain/entities/feed_stock.dart';

class FeedStockModel extends FeedStock {
  FeedStockModel({
    required super.id,
    required super.type,
    super.brand,
    required super.currentQuantityKg,
    super.minimumQuantityKg,
    super.pricePerKg,
    super.notes,
    required super.lastUpdated,
    required super.createdAt,
  });

  factory FeedStockModel.fromJson(Map<String, dynamic> json) {
    return FeedStockModel(
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

  factory FeedStockModel.fromEntity(FeedStock entity) {
    return FeedStockModel(
      id: entity.id,
      type: entity.type,
      brand: entity.brand,
      currentQuantityKg: entity.currentQuantityKg,
      minimumQuantityKg: entity.minimumQuantityKg,
      pricePerKg: entity.pricePerKg,
      notes: entity.notes,
      lastUpdated: entity.lastUpdated,
      createdAt: entity.createdAt,
    );
  }
}

class FeedMovementModel extends FeedMovement {
  FeedMovementModel({
    required super.id,
    required super.feedStockId,
    required super.movementType,
    required super.quantityKg,
    super.cost,
    required super.date,
    super.notes,
    required super.createdAt,
  });

  factory FeedMovementModel.fromJson(Map<String, dynamic> json) {
    return FeedMovementModel(
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

  factory FeedMovementModel.fromEntity(FeedMovement entity) {
    return FeedMovementModel(
      id: entity.id,
      feedStockId: entity.feedStockId,
      movementType: entity.movementType,
      quantityKg: entity.quantityKg,
      cost: entity.cost,
      date: entity.date,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
