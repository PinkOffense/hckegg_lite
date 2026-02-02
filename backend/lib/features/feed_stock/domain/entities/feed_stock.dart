import 'package:equatable/equatable.dart';

/// Feed types matching database schema
/// Values: layer, grower, starter, scratch, supplement, other
enum FeedType {
  layer,
  grower,
  starter,
  scratch,
  supplement,
  other;

  static FeedType fromString(String value) {
    return FeedType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeedType.other,
    );
  }
}

/// Stock movement types matching database schema
/// Values: purchase, consumption, adjustment, loss
enum StockMovementType {
  purchase,
  consumption,
  adjustment,
  loss;

  static StockMovementType fromString(String value) {
    return StockMovementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockMovementType.adjustment,
    );
  }
}

/// Domain entity for feed stock inventory
/// Matches database schema: feed_stocks table
class FeedStock extends Equatable {
  const FeedStock({
    required this.id,
    required this.userId,
    required this.type,
    this.brand,
    required this.currentQuantityKg,
    required this.minimumQuantityKg,
    this.pricePerKg,
    this.notes,
    required this.lastUpdated,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final FeedType type;
  final String? brand;
  final double currentQuantityKg;
  final double minimumQuantityKg;
  final double? pricePerKg;
  final String? notes;
  final DateTime lastUpdated;
  final DateTime createdAt;

  /// Check if stock is below minimum level
  bool get isLowStock => currentQuantityKg <= minimumQuantityKg;

  FeedStock copyWith({
    String? id,
    String? userId,
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
      userId: userId ?? this.userId,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'brand': brand,
        'current_quantity_kg': currentQuantityKg,
        'minimum_quantity_kg': minimumQuantityKg,
        'price_per_kg': pricePerKg,
        'notes': notes,
        'last_updated': lastUpdated.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory FeedStock.fromJson(Map<String, dynamic> json) => FeedStock(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: FeedType.fromString(json['type'] as String),
        brand: json['brand'] as String?,
        currentQuantityKg: (json['current_quantity_kg'] as num).toDouble(),
        minimumQuantityKg:
            (json['minimum_quantity_kg'] as num?)?.toDouble() ?? 10.0,
        pricePerKg: (json['price_per_kg'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        lastUpdated: DateTime.parse(json['last_updated'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        brand,
        currentQuantityKg,
        minimumQuantityKg,
        pricePerKg,
        notes,
        lastUpdated,
        createdAt,
      ];
}

/// Domain entity for feed stock movements
/// Matches database schema: feed_movements table
class FeedMovement extends Equatable {
  const FeedMovement({
    required this.id,
    required this.userId,
    required this.feedStockId,
    required this.movementType,
    required this.quantityKg,
    this.cost,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String feedStockId;
  final StockMovementType movementType;
  final double quantityKg;
  final double? cost;
  final String date; // Format: YYYY-MM-DD
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'feed_stock_id': feedStockId,
        'movement_type': movementType.name,
        'quantity_kg': quantityKg,
        'cost': cost,
        'date': date,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory FeedMovement.fromJson(Map<String, dynamic> json) => FeedMovement(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        feedStockId: json['feed_stock_id'] as String,
        movementType:
            StockMovementType.fromString(json['movement_type'] as String),
        quantityKg: (json['quantity_kg'] as num).toDouble(),
        cost: (json['cost'] as num?)?.toDouble(),
        date: json['date'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        feedStockId,
        movementType,
        quantityKg,
        cost,
        date,
        notes,
        createdAt,
      ];
}
