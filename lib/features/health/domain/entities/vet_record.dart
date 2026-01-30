import 'package:equatable/equatable.dart';

enum VetRecordType {
  vaccine,
  disease,
  treatment,
  death,
  checkup;

  String displayName(String locale) {
    if (locale == 'pt') {
      switch (this) {
        case VetRecordType.vaccine: return 'Vacina';
        case VetRecordType.disease: return 'Doença';
        case VetRecordType.treatment: return 'Tratamento';
        case VetRecordType.death: return 'Morte';
        case VetRecordType.checkup: return 'Exame de Rotina';
      }
    } else {
      switch (this) {
        case VetRecordType.vaccine: return 'Vaccine';
        case VetRecordType.disease: return 'Disease';
        case VetRecordType.treatment: return 'Treatment';
        case VetRecordType.death: return 'Death';
        case VetRecordType.checkup: return 'Checkup';
      }
    }
  }
}

enum VetRecordSeverity {
  low,
  medium,
  high,
  critical;

  String displayName(String locale) {
    if (locale == 'pt') {
      switch (this) {
        case VetRecordSeverity.low: return 'Baixa';
        case VetRecordSeverity.medium: return 'Média';
        case VetRecordSeverity.high: return 'Alta';
        case VetRecordSeverity.critical: return 'Crítica';
      }
    } else {
      switch (this) {
        case VetRecordSeverity.low: return 'Low';
        case VetRecordSeverity.medium: return 'Medium';
        case VetRecordSeverity.high: return 'High';
        case VetRecordSeverity.critical: return 'Critical';
      }
    }
  }
}

class VetRecord extends Equatable {
  final String id;
  final String date;
  final VetRecordType type;
  final int hensAffected;
  final String description;
  final String? medication;
  final double? cost;
  final String? nextActionDate;
  final String? notes;
  final VetRecordSeverity severity;
  final DateTime createdAt;

  const VetRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.hensAffected,
    required this.description,
    this.medication,
    this.cost,
    this.nextActionDate,
    this.notes,
    this.severity = VetRecordSeverity.low,
    required this.createdAt,
  });

  VetRecord copyWith({
    String? id,
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
  }) {
    return VetRecord(
      id: id ?? this.id,
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
    );
  }

  @override
  List<Object?> get props => [
        id, date, type, hensAffected, description, medication,
        cost, nextActionDate, notes, severity, createdAt,
      ];
}
