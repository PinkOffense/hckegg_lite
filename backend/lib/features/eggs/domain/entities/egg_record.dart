import 'package:equatable/equatable.dart';

/// Domain entity for daily egg record
/// Matches database schema: daily_egg_records table
class EggRecord extends Equatable {
  const EggRecord({
    required this.id,
    required this.userId,
    this.farmId,
    required this.date,
    required this.eggsCollected,
    required this.eggsConsumed,
    this.notes,
    this.henCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? farmId;
  final String date; // Format: YYYY-MM-DD
  final int eggsCollected;
  final int eggsConsumed;
  final String? notes;
  final int? henCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Calculate eggs remaining (collected - consumed)
  int get eggsRemaining => eggsCollected - eggsConsumed;

  /// Create a copy with updated fields
  EggRecord copyWith({
    String? id,
    String? userId,
    String? farmId,
    String? date,
    int? eggsCollected,
    int? eggsConsumed,
    String? notes,
    int? henCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EggRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmId: farmId ?? this.farmId,
      date: date ?? this.date,
      eggsCollected: eggsCollected ?? this.eggsCollected,
      eggsConsumed: eggsConsumed ?? this.eggsConsumed,
      notes: notes ?? this.notes,
      henCount: henCount ?? this.henCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'farm_id': farmId,
      'date': date,
      'eggs_collected': eggsCollected,
      'eggs_consumed': eggsConsumed,
      'notes': notes,
      'hen_count': henCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EggRecord.fromJson(Map<String, dynamic> json) {
    return EggRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      farmId: json['farm_id'] as String?,
      date: json['date'] as String,
      eggsCollected: json['eggs_collected'] as int,
      eggsConsumed: json['eggs_consumed'] as int? ?? 0,
      notes: json['notes'] as String?,
      henCount: json['hen_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        farmId,
        date,
        eggsCollected,
        eggsConsumed,
        notes,
        henCount,
        createdAt,
        updatedAt,
      ];
}
