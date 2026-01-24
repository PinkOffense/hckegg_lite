class DailyEggRecord {
  final String id;
  final String date; // Format: "YYYY-MM-DD"
  final int eggsCollected;
  final int eggsConsumed;
  final String? notes;
  final int? henCount;
  final DateTime createdAt;

  DailyEggRecord({
    required this.id,
    required this.date,
    required this.eggsCollected,
    this.eggsConsumed = 0,
    this.notes,
    this.henCount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate eggs remaining (not consumed)
  int get eggsRemaining => eggsCollected - eggsConsumed;

  DailyEggRecord copyWith({
    String? id,
    String? date,
    int? eggsCollected,
    int? eggsConsumed,
    String? notes,
    int? henCount,
    DateTime? createdAt,
  }) {
    return DailyEggRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      eggsCollected: eggsCollected ?? this.eggsCollected,
      eggsConsumed: eggsConsumed ?? this.eggsConsumed,
      notes: notes ?? this.notes,
      henCount: henCount ?? this.henCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'eggs_collected': eggsCollected,
      'eggs_consumed': eggsConsumed,
      'notes': notes,
      'hen_count': henCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyEggRecord.fromJson(Map<String, dynamic> json) {
    return DailyEggRecord(
      id: json['id'] as String,
      date: json['date'] as String,
      eggsCollected: json['eggs_collected'] as int,
      eggsConsumed: json['eggs_consumed'] as int? ?? 0,
      notes: json['notes'] as String?,
      henCount: json['hen_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
