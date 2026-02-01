import 'package:equatable/equatable.dart';

/// Domain entity for daily egg record
class EggRecord extends Equatable {
  const EggRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.eggsCollected,
    required this.eggsBroken,
    required this.eggsConsumed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String date; // Format: YYYY-MM-DD
  final int eggsCollected;
  final int eggsBroken;
  final int eggsConsumed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Calculate eggs available for sale
  int get eggsAvailable => eggsCollected - eggsBroken - eggsConsumed;

  /// Create a copy with updated fields
  EggRecord copyWith({
    String? id,
    String? userId,
    String? date,
    int? eggsCollected,
    int? eggsBroken,
    int? eggsConsumed,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EggRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      eggsCollected: eggsCollected ?? this.eggsCollected,
      eggsBroken: eggsBroken ?? this.eggsBroken,
      eggsConsumed: eggsConsumed ?? this.eggsConsumed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'eggs_collected': eggsCollected,
      'eggs_broken': eggsBroken,
      'eggs_consumed': eggsConsumed,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EggRecord.fromJson(Map<String, dynamic> json) {
    return EggRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      eggsCollected: json['eggs_collected'] as int,
      eggsBroken: json['eggs_broken'] as int? ?? 0,
      eggsConsumed: json['eggs_consumed'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        eggsCollected,
        eggsBroken,
        eggsConsumed,
        notes,
        createdAt,
        updatedAt,
      ];
}
