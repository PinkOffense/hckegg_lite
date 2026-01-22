class DailyEggRecord {
  final String id;
  final String date; // Format: "YYYY-MM-DD"
  final int eggsCollected;
  final int eggsSold;
  final int eggsConsumed;
  final double? pricePerEgg;
  final String? notes;
  final int? henCount;
  final double? feedExpense;      // Despesa com ração
  final double? vetExpense;       // Despesa veterinária
  final double? otherExpense;     // Outras despesas
  final DateTime createdAt;

  DailyEggRecord({
    required this.id,
    required this.date,
    required this.eggsCollected,
    this.eggsSold = 0,
    this.eggsConsumed = 0,
    this.pricePerEgg,
    this.notes,
    this.henCount,
    this.feedExpense,
    this.vetExpense,
    this.otherExpense,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate eggs remaining (not sold or consumed)
  int get eggsRemaining => eggsCollected - eggsSold - eggsConsumed;

  // Calculate revenue for this day
  double get revenue => (pricePerEgg ?? 0) * eggsSold;

  // Calculate total expenses for this day
  double get totalExpenses => (feedExpense ?? 0) + (vetExpense ?? 0) + (otherExpense ?? 0);

  // Calculate net profit (revenue - expenses)
  double get netProfit => revenue - totalExpenses;

  DailyEggRecord copyWith({
    String? id,
    String? date,
    int? eggsCollected,
    int? eggsSold,
    int? eggsConsumed,
    double? pricePerEgg,
    String? notes,
    int? henCount,
    double? feedExpense,
    double? vetExpense,
    double? otherExpense,
    DateTime? createdAt,
  }) {
    return DailyEggRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      eggsCollected: eggsCollected ?? this.eggsCollected,
      eggsSold: eggsSold ?? this.eggsSold,
      eggsConsumed: eggsConsumed ?? this.eggsConsumed,
      pricePerEgg: pricePerEgg ?? this.pricePerEgg,
      notes: notes ?? this.notes,
      henCount: henCount ?? this.henCount,
      feedExpense: feedExpense ?? this.feedExpense,
      vetExpense: vetExpense ?? this.vetExpense,
      otherExpense: otherExpense ?? this.otherExpense,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'eggs_collected': eggsCollected,
      'eggs_sold': eggsSold,
      'eggs_consumed': eggsConsumed,
      'price_per_egg': pricePerEgg,
      'notes': notes,
      'hen_count': henCount,
      'feed_expense': feedExpense,
      'vet_expense': vetExpense,
      'other_expense': otherExpense,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyEggRecord.fromJson(Map<String, dynamic> json) {
    return DailyEggRecord(
      id: json['id'] as String,
      date: json['date'] as String,
      eggsCollected: json['eggs_collected'] as int,
      eggsSold: json['eggs_sold'] as int? ?? 0,
      eggsConsumed: json['eggs_consumed'] as int? ?? 0,
      pricePerEgg: json['price_per_egg'] != null
          ? (json['price_per_egg'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      henCount: json['hen_count'] as int?,
      feedExpense: json['feed_expense'] != null
          ? (json['feed_expense'] as num).toDouble()
          : null,
      vetExpense: json['vet_expense'] != null
          ? (json['vet_expense'] as num).toDouble()
          : null,
      otherExpense: json['other_expense'] != null
          ? (json['other_expense'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
