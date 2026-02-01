import 'package:equatable/equatable.dart';

enum ReservationStatus {
  pending,
  confirmed,
  delivered,
  cancelled;

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.userId,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.quantity,
    required this.pricePerEgg,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String date;
  final String customerName;
  final String customerPhone;
  final int quantity;
  final double pricePerEgg;
  final ReservationStatus status;
  final String? notes;
  final DateTime createdAt;

  double get totalAmount => quantity * pricePerEgg;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'quantity': quantity,
        'price_per_egg': pricePerEgg,
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'total_amount': totalAmount,
      };

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: json['date'] as String,
        customerName: json['customer_name'] as String,
        customerPhone: json['customer_phone'] as String,
        quantity: json['quantity'] as int,
        pricePerEgg: (json['price_per_egg'] as num).toDouble(),
        status: ReservationStatus.fromString(json['status'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, date, customerName, quantity, status];
}
