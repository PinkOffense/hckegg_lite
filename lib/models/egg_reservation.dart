class EggReservation {
  final String id;
  final String date; // Date of reservation
  final String? pickupDate; // Expected pickup date
  final int quantity;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final double? pricePerEgg; // Optional: lock in price at reservation time
  final double? pricePerDozen; // Optional: lock in price at reservation time
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

  factory EggReservation.fromJson(Map<String, dynamic> json) {
    return EggReservation(
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
}
