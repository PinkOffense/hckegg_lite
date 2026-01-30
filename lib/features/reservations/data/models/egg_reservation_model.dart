import '../../domain/entities/egg_reservation.dart';

class EggReservationModel extends EggReservation {
  const EggReservationModel({
    required super.id,
    required super.date,
    super.pickupDate,
    required super.quantity,
    super.customerName,
    super.customerEmail,
    super.customerPhone,
    super.notes,
    super.pricePerEgg,
    super.pricePerDozen,
    required super.createdAt,
  });

  factory EggReservationModel.fromJson(Map<String, dynamic> json) {
    return EggReservationModel(
      id: json['id'] as String,
      date: json['date'] as String,
      pickupDate: json['pickup_date'] as String?,
      quantity: json['quantity'] as int,
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      notes: json['notes'] as String?,
      pricePerEgg: json['price_per_egg'] != null
          ? (json['price_per_egg'] as num).toDouble()
          : null,
      pricePerDozen: json['price_per_dozen'] != null
          ? (json['price_per_dozen'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'pickup_date': pickupDate,
      'quantity': quantity,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'notes': notes,
      'price_per_egg': pricePerEgg,
      'price_per_dozen': pricePerDozen,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EggReservationModel.fromEntity(EggReservation entity) {
    return EggReservationModel(
      id: entity.id,
      date: entity.date,
      pickupDate: entity.pickupDate,
      quantity: entity.quantity,
      customerName: entity.customerName,
      customerEmail: entity.customerEmail,
      customerPhone: entity.customerPhone,
      notes: entity.notes,
      pricePerEgg: entity.pricePerEgg,
      pricePerDozen: entity.pricePerDozen,
      createdAt: entity.createdAt,
    );
  }
}
