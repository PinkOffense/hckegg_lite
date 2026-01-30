import '../../domain/entities/vet_record.dart';

class VetRecordModel extends VetRecord {
  VetRecordModel({
    required super.id,
    required super.date,
    required super.type,
    required super.hensAffected,
    required super.description,
    super.medication,
    super.cost,
    super.nextActionDate,
    super.notes,
    super.severity,
    required super.createdAt,
  });

  factory VetRecordModel.fromEntity(VetRecord entity) {
    return VetRecordModel(
      id: entity.id,
      date: entity.date,
      type: entity.type,
      hensAffected: entity.hensAffected,
      description: entity.description,
      medication: entity.medication,
      cost: entity.cost,
      nextActionDate: entity.nextActionDate,
      notes: entity.notes,
      severity: entity.severity,
      createdAt: entity.createdAt,
    );
  }

  factory VetRecordModel.fromJson(Map<String, dynamic> json) {
    return VetRecordModel(
      id: json['id'] as String,
      date: json['date'] as String,
      type: VetRecordType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VetRecordType.checkup,
      ),
      hensAffected: json['hens_affected'] as int,
      description: json['description'] as String,
      medication: json['medication'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      nextActionDate: json['next_action_date'] as String?,
      notes: json['notes'] as String?,
      severity: VetRecordSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => VetRecordSeverity.low,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
    };
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
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
    };
  }

  VetRecord toEntity() => this;
}
