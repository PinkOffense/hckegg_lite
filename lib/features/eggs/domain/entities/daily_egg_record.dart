import 'package:equatable/equatable.dart';

/// Domain entity representing a daily egg record
/// This is a pure business object with no framework dependencies
class DailyEggRecord extends Equatable {
  final String id;
  final String date; // Format: "YYYY-MM-DD"
  final int eggsCollected;
  final int eggsConsumed;
  final String? notes;
  final int? henCount;
  final DateTime createdAt;

  const DailyEggRecord({
    required this.id,
    required this.date,
    required this.eggsCollected,
    this.eggsConsumed = 0,
    this.notes,
    this.henCount,
    required this.createdAt,
  });

  /// Calculate eggs remaining (not consumed)
  int get eggsRemaining => eggsCollected - eggsConsumed;

  /// Create a copy with updated fields
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

  @override
  List<Object?> get props => [id, date, eggsCollected, eggsConsumed, notes, henCount, createdAt];
}
