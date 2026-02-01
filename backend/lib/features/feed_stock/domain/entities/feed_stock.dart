import 'package:equatable/equatable.dart';

class FeedStock extends Equatable {
  const FeedStock({
    required this.id,
    required this.userId,
    required this.date,
    required this.feedType,
    required this.quantityKg,
    required this.cost,
    this.supplier,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String date;
  final String feedType;
  final double quantityKg;
  final double cost;
  final String? supplier;
  final String? notes;
  final DateTime createdAt;

  double get costPerKg => quantityKg > 0 ? cost / quantityKg : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'feed_type': feedType,
        'quantity_kg': quantityKg,
        'cost': cost,
        'supplier': supplier,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'cost_per_kg': costPerKg,
      };

  factory FeedStock.fromJson(Map<String, dynamic> json) => FeedStock(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: json['date'] as String,
        feedType: json['feed_type'] as String,
        quantityKg: (json['quantity_kg'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        supplier: json['supplier'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, date, feedType, quantityKg, cost];
}
