import 'package:equatable/equatable.dart';

/// Payment status for a sale
enum PaymentStatus {
  paid,
  pending,
  overdue,
  advance;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Domain entity for egg sale
class Sale extends Equatable {
  const Sale({
    required this.id,
    required this.userId,
    this.farmId,
    required this.date,
    required this.quantitySold,
    required this.pricePerEgg,
    required this.pricePerDozen,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    required this.paymentStatus,
    this.paymentDate,
    required this.isReservation,
    this.reservationNotes,
    required this.isLost,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? farmId;
  final String date;
  final int quantitySold;
  final double pricePerEgg;
  final double pricePerDozen;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final PaymentStatus paymentStatus;
  final String? paymentDate;
  final bool isReservation;
  final String? reservationNotes;
  final bool isLost;
  final DateTime createdAt;

  double get totalAmount => quantitySold * pricePerEgg;
  int get dozens => quantitySold ~/ 12;
  int get individualEggs => quantitySold % 12;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'farm_id': farmId,
        'date': date,
        'quantity_sold': quantitySold,
        'price_per_egg': pricePerEgg,
        'price_per_dozen': pricePerDozen,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'notes': notes,
        'payment_status': paymentStatus.name,
        'payment_date': paymentDate,
        'is_reservation': isReservation,
        'reservation_notes': reservationNotes,
        'is_lost': isLost,
        'created_at': createdAt.toIso8601String(),
        'total_amount': totalAmount,
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        farmId: json['farm_id'] as String?,
        date: json['date'] as String,
        quantitySold: json['quantity_sold'] as int,
        pricePerEgg: (json['price_per_egg'] as num).toDouble(),
        pricePerDozen: (json['price_per_dozen'] as num).toDouble(),
        customerName: json['customer_name'] as String?,
        customerEmail: json['customer_email'] as String?,
        customerPhone: json['customer_phone'] as String?,
        notes: json['notes'] as String?,
        paymentStatus: PaymentStatus.fromString(
          json['payment_status'] as String? ?? 'pending',
        ),
        paymentDate: json['payment_date'] as String?,
        isReservation: json['is_reservation'] as bool? ?? false,
        reservationNotes: json['reservation_notes'] as String?,
        isLost: json['is_lost'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, date, quantitySold, paymentStatus];
}
