class Vaccine {
  final int? id;
  final int? chickenId; // null means it applies to all chickens
  final String name;
  final String? description;
  final DateTime vaccinationDate;
  final DateTime? nextDueDate;
  final String? administeredBy;
  final String? notes;
  final DateTime createdAt;

  Vaccine({
    this.id,
    this.chickenId,
    required this.name,
    this.description,
    required this.vaccinationDate,
    this.nextDueDate,
    this.administeredBy,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  int get daysUntilDue {
    if (nextDueDate == null) return 0;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }

  bool get isDueSoon {
    if (nextDueDate == null) return false;
    return daysUntilDue <= 7 && daysUntilDue >= 0;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chicken_id': chickenId,
      'name': name,
      'description': description,
      'vaccination_date': vaccinationDate.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'administered_by': administeredBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'] as int?,
      chickenId: map['chicken_id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      vaccinationDate: DateTime.parse(map['vaccination_date'] as String),
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'] as String)
          : null,
      administeredBy: map['administered_by'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Copy with
  Vaccine copyWith({
    int? id,
    int? chickenId,
    String? name,
    String? description,
    DateTime? vaccinationDate,
    DateTime? nextDueDate,
    String? administeredBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return Vaccine(
      id: id ?? this.id,
      chickenId: chickenId ?? this.chickenId,
      name: name ?? this.name,
      description: description ?? this.description,
      vaccinationDate: vaccinationDate ?? this.vaccinationDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      administeredBy: administeredBy ?? this.administeredBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
