import 'package:equatable/equatable.dart';

/// Domain entity for egg reservations
/// Matches database schema: egg_reservations table
class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.userId,
    this.farmId,
    required this.date,
    this.pickupDate,
    required this.quantity,
    this.pricePerEgg,
    this.pricePerDozen,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? farmId;
  final String date; // Format: YYYY-MM-DD (reservation date)
  final String? pickupDate; // Format: YYYY-MM-DD (expected pickup)
  final int quantity;
  final double? pricePerEgg;
  final double? pricePerDozen;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final DateTime createdAt;

  /// Calculate total amount based on price per egg
  double? get totalAmount =>
      pricePerEgg != null ? quantity * pricePerEgg! : null;

  Reservation copyWith({
    String? id,
    String? userId,
    String? farmId,
    String? date,
    String? pickupDate,
    int? quantity,
    double? pricePerEgg,
    double? pricePerDozen,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmId: farmId ?? this.farmId,
      date: date ?? this.date,
      pickupDate: pickupDate ?? this.pickupDate,
      quantity: quantity ?? this.quantity,
      pricePerEgg: pricePerEgg ?? this.pricePerEgg,
      pricePerDozen: pricePerDozen ?? this.pricePerDozen,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'farm_id': farmId,
        'date': date,
        'pickup_date': pickupDate,
        'quantity': quantity,
        'price_per_egg': pricePerEgg,
        'price_per_dozen': pricePerDozen,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        farmId: json['farm_id'] as String?,
        date: json['date'] as String,
        pickupDate: json['pickup_date'] as String?,
        quantity: json['quantity'] as int,
        pricePerEgg: (json['price_per_egg'] as num?)?.toDouble(),
        pricePerDozen: (json['price_per_dozen'] as num?)?.toDouble(),
        customerName: json['customer_name'] as String?,
        customerEmail: json['customer_email'] as String?,
        customerPhone: json['customer_phone'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        farmId,
        date,
        pickupDate,
        quantity,
        pricePerEgg,
        pricePerDozen,
        customerName,
        customerEmail,
        customerPhone,
        notes,
        createdAt,
      ];
}
