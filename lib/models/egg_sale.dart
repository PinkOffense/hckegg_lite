enum PaymentStatus {
  paid,
  pending,
  overdue,
  advance; // Paid in advance

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.overdue:
        return 'Atrasado';
      case PaymentStatus.advance:
        return 'Adiantado';
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class EggSale {
  final String id;
  final String date; // Format: "YYYY-MM-DD"
  final int quantitySold;
  final double pricePerEgg;
  final double pricePerDozen;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;
  final PaymentStatus paymentStatus;
  final String? paymentDate; // Format: "YYYY-MM-DD"
  final bool isReservation;
  final String? reservationNotes;
  final bool isLost; // Mark sale as lost (customer never paid)
  final DateTime createdAt;

  EggSale({
    required this.id,
    required this.date,
    required this.quantitySold,
    required this.pricePerEgg,
    required this.pricePerDozen,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentDate,
    this.isReservation = false,
    this.reservationNotes,
    this.isLost = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate total amount for this sale
  double get totalAmount => quantitySold * pricePerEgg;

  // Calculate how many dozens and individual eggs
  int get dozens => quantitySold ~/ 12;
  int get individualEggs => quantitySold % 12;

  // Calculate total if priced by dozen + individual
  double get totalByDozen => (dozens * pricePerDozen) + (individualEggs * pricePerEgg);

  EggSale copyWith({
    String? id,
    String? date,
    int? quantitySold,
    double? pricePerEgg,
    double? pricePerDozen,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    PaymentStatus? paymentStatus,
    String? paymentDate,
    bool? isReservation,
    String? reservationNotes,
    bool? isLost,
    DateTime? createdAt,
  }) {
    return EggSale(
      id: id ?? this.id,
      date: date ?? this.date,
      quantitySold: quantitySold ?? this.quantitySold,
      pricePerEgg: pricePerEgg ?? this.pricePerEgg,
      pricePerDozen: pricePerDozen ?? this.pricePerDozen,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      isReservation: isReservation ?? this.isReservation,
      reservationNotes: reservationNotes ?? this.reservationNotes,
      isLost: isLost ?? this.isLost,
      createdAt: createdAt ?? this.createdAt,
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

  factory EggSale.fromJson(Map<String, dynamic> json) {
    return EggSale(
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
}
