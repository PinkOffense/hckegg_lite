import '../../domain/entities/daily_egg_record.dart';

/// Data model for DailyEggRecord with JSON serialization
/// Extends the domain entity to add serialization capabilities
class DailyEggRecordModel extends DailyEggRecord {
  const DailyEggRecordModel({
    required super.id,
    required super.date,
    required super.eggsCollected,
    super.eggsConsumed,
    super.notes,
    super.henCount,
    required super.createdAt,
  });

  /// Create model from domain entity
  factory DailyEggRecordModel.fromEntity(DailyEggRecord entity) {
    return DailyEggRecordModel(
      id: entity.id,
      date: entity.date,
      eggsCollected: entity.eggsCollected,
      eggsConsumed: entity.eggsConsumed,
      notes: entity.notes,
      henCount: entity.henCount,
      createdAt: entity.createdAt,
    );
  }

  /// Create model from JSON (Supabase response)
  factory DailyEggRecordModel.fromJson(Map<String, dynamic> json) {
    return DailyEggRecordModel(
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

  /// Convert to JSON for Supabase
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

  /// Convert to JSON for insert (without id, let Supabase generate it)
  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'date': date,
      'eggs_collected': eggsCollected,
      'eggs_consumed': eggsConsumed,
      'notes': notes,
      'hen_count': henCount,
    };
  }

  /// Convert to JSON for update
  Map<String, dynamic> toUpdateJson() {
    return {
      'date': date,
      'eggs_collected': eggsCollected,
      'eggs_consumed': eggsConsumed,
      'notes': notes,
      'hen_count': henCount,
    };
  }

  /// Convert to domain entity
  DailyEggRecord toEntity() {
    return DailyEggRecord(
      id: id,
      date: date,
      eggsCollected: eggsCollected,
      eggsConsumed: eggsConsumed,
      notes: notes,
      henCount: henCount,
      createdAt: createdAt,
    );
  }
}
