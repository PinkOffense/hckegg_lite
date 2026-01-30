import 'package:equatable/equatable.dart';

class EggReservation extends Equatable {
  final String id;
  final String date;
  final String? pickupDate;
  final int quantity;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final double? pricePerEgg;
  final double? pricePerDozen;
  final DateTime createdAt;

  const EggReservation({
    required this.id,
    required this.date,
    this.pickupDate,
    required this.quantity,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    this.pricePerEgg,
    this.pricePerDozen,
    required this.createdAt,
  });

  EggReservation copyWith({
    String? id,
    String? date,
    String? pickupDate,
    int? quantity,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    double? pricePerEgg,
    double? pricePerDozen,
    DateTime? createdAt,
  }) {
    return EggReservation(
      id: id ?? this.id,
      date: date ?? this.date,
      pickupDate: pickupDate ?? this.pickupDate,
      quantity: quantity ?? this.quantity,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      pricePerEgg: pricePerEgg ?? this.pricePerEgg,
      pricePerDozen: pricePerDozen ?? this.pricePerDozen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, date, pickupDate, quantity, customerName, customerEmail,
        customerPhone, notes, pricePerEgg, pricePerDozen, createdAt,
      ];
}
