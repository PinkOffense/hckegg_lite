import 'package:equatable/equatable.dart';

/// Vet record types matching database schema
/// Values: vaccine, disease, treatment, death, checkup
enum VetRecordType {
  vaccine,
  disease,
  treatment,
  death,
  checkup;

  static VetRecordType fromString(String value) {
    return VetRecordType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VetRecordType.checkup,
    );
  }
}

/// Vet record severity levels matching database schema
/// Values: low, medium, high, critical
enum VetRecordSeverity {
  low,
  medium,
  high,
  critical;

  static VetRecordSeverity fromString(String value) {
    return VetRecordSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VetRecordSeverity.low,
    );
  }
}

/// Domain entity for veterinary records
/// Matches database schema: vet_records table
class VetRecord extends Equatable {
  const VetRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.hensAffected,
    required this.description,
    this.medication,
    this.cost,
    this.nextActionDate,
    this.notes,
    required this.severity,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String date; // Format: YYYY-MM-DD
  final VetRecordType type;
  final int hensAffected;
  final String description;
  final String? medication;
  final double? cost;
  final String? nextActionDate; // Format: YYYY-MM-DD
  final String? notes;
  final VetRecordSeverity severity;
  final DateTime createdAt;
  final DateTime updatedAt;

  VetRecord copyWith({
    String? id,
    String? userId,
    String? date,
    VetRecordType? type,
    int? hensAffected,
    String? description,
    String? medication,
    double? cost,
    String? nextActionDate,
    String? notes,
    VetRecordSeverity? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VetRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      type: type ?? this.type,
      hensAffected: hensAffected ?? this.hensAffected,
      description: description ?? this.description,
      medication: medication ?? this.medication,
      cost: cost ?? this.cost,
      nextActionDate: nextActionDate ?? this.nextActionDate,
      notes: notes ?? this.notes,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'type': type.name,
        'hens_affected': hensAffected,
        'description': description,
        'medication': medication,
        'cost': cost,
        'next_action_date': nextActionDate,
        'notes': notes,
        'severity': severity.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VetRecord.fromJson(Map<String, dynamic> json) => VetRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: json['date'] as String,
        type: VetRecordType.fromString(json['type'] as String),
        hensAffected: json['hens_affected'] as int,
        description: json['description'] as String,
        medication: json['medication'] as String?,
        cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
        nextActionDate: json['next_action_date'] as String?,
        notes: json['notes'] as String?,
        severity: VetRecordSeverity.fromString(
          (json['severity'] as String?) ?? 'low',
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        type,
        hensAffected,
        description,
        medication,
        cost,
        nextActionDate,
        notes,
        severity,
        createdAt,
        updatedAt,
      ];
}
