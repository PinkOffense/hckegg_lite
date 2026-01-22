class VetRecord {
  final String id;
  final String date; // Format: "YYYY-MM-DD"
  final VetRecordType type;
  final int hensAffected;
  final String description;
  final String? medication;
  final double? cost;
  final String? nextActionDate; // Format: "YYYY-MM-DD"
  final String? notes;
  final VetRecordSeverity severity;
  final DateTime createdAt;

  VetRecord({
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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

  factory VetRecord.fromJson(Map<String, dynamic> json) {
    return VetRecord(
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
}

enum VetRecordType {
  vaccine,      // Vacina
  disease,      // Doença
  treatment,    // Tratamento
  death,        // Morte
  checkup,      // Exame de rotina
}

enum VetRecordSeverity {
  low,          // Baixa
  medium,       // Média
  high,         // Alta
  critical,     // Crítica
}

// Extension for display names
extension VetRecordTypeExtension on VetRecordType {
  String displayName(String locale) {
    if (locale == 'pt') {
      switch (this) {
        case VetRecordType.vaccine:
          return 'Vacina';
        case VetRecordType.disease:
          return 'Doença';
        case VetRecordType.treatment:
          return 'Tratamento';
        case VetRecordType.death:
          return 'Morte';
        case VetRecordType.checkup:
          return 'Exame de Rotina';
      }
    } else {
      switch (this) {
        case VetRecordType.vaccine:
          return 'Vaccine';
        case VetRecordType.disease:
          return 'Disease';
        case VetRecordType.treatment:
          return 'Treatment';
        case VetRecordType.death:
          return 'Death';
        case VetRecordType.checkup:
          return 'Checkup';
      }
    }
  }
}

extension VetRecordSeverityExtension on VetRecordSeverity {
  String displayName(String locale) {
    if (locale == 'pt') {
      switch (this) {
        case VetRecordSeverity.low:
          return 'Baixa';
        case VetRecordSeverity.medium:
          return 'Média';
        case VetRecordSeverity.high:
          return 'Alta';
        case VetRecordSeverity.critical:
          return 'Crítica';
      }
    } else {
      switch (this) {
        case VetRecordSeverity.low:
          return 'Low';
        case VetRecordSeverity.medium:
          return 'Medium';
        case VetRecordSeverity.high:
          return 'High';
        case VetRecordSeverity.critical:
          return 'Critical';
      }
    }
  }
}
