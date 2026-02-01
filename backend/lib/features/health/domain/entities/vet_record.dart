import 'package:equatable/equatable.dart';

enum VetRecordType {
  checkup,
  treatment,
  vaccination,
  medication;

  static VetRecordType fromString(String value) {
    return VetRecordType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VetRecordType.checkup,
    );
  }
}

class VetRecord extends Equatable {
  const VetRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.recordType,
    required this.hensAffected,
    required this.description,
    this.vetName,
    required this.cost,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String date;
  final VetRecordType recordType;
  final int hensAffected;
  final String description;
  final String? vetName;
  final double cost;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'record_type': recordType.name,
        'hens_affected': hensAffected,
        'description': description,
        'vet_name': vetName,
        'cost': cost,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory VetRecord.fromJson(Map<String, dynamic> json) => VetRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: json['date'] as String,
        recordType: VetRecordType.fromString(json['record_type'] as String),
        hensAffected: json['hens_affected'] as int,
        description: json['description'] as String,
        vetName: json['vet_name'] as String?,
        cost: (json['cost'] as num).toDouble(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, date, recordType, hensAffected, cost];
}
