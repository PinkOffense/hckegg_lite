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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
