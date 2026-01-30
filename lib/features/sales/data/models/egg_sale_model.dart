import '../../domain/entities/egg_sale.dart';

class EggSaleModel extends EggSale {
  const EggSaleModel({
    required super.id,
    required super.date,
    required super.quantitySold,
    required super.pricePerEgg,
    required super.pricePerDozen,
    super.customerName,
    super.customerEmail,
    super.customerPhone,
    super.notes,
    super.paymentStatus,
    super.paymentDate,
    super.isReservation,
    super.reservationNotes,
    super.isLost,
    required super.createdAt,
  });

  factory EggSaleModel.fromEntity(EggSale entity) {
    return EggSaleModel(
      id: entity.id,
      date: entity.date,
      quantitySold: entity.quantitySold,
      pricePerEgg: entity.pricePerEgg,
      pricePerDozen: entity.pricePerDozen,
      customerName: entity.customerName,
      customerEmail: entity.customerEmail,
      customerPhone: entity.customerPhone,
      notes: entity.notes,
      paymentStatus: entity.paymentStatus,
      paymentDate: entity.paymentDate,
      isReservation: entity.isReservation,
      reservationNotes: entity.reservationNotes,
      isLost: entity.isLost,
      createdAt: entity.createdAt,
    );
  }

  factory EggSaleModel.fromJson(Map<String, dynamic> json) {
    return EggSaleModel(
      id: json['id'] as String,
      date: json['date'] as String,
      quantitySold: json['quantity_sold'] as int,
      pricePerEgg: (json['price_per_egg'] as num).toDouble(),
      pricePerDozen: (json['price_per_dozen'] as num).toDouble(),
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      notes: json['notes'] as String?,
      paymentStatus: json['payment_status'] != null
          ? PaymentStatus.fromString(json['payment_status'] as String)
          : PaymentStatus.pending,
      paymentDate: json['payment_date'] as String?,
      isReservation: json['is_reservation'] as bool? ?? false,
      reservationNotes: json['reservation_notes'] as String?,
      isLost: json['is_lost'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
    };
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
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
    };
  }

  EggSale toEntity() => this;
}
