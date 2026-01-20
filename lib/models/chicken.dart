class Chicken {
  final int? id;
  final String name;
  final String breed;
  final DateTime birthDate;
  final String? photoPath;
  final String sex; // 'Macho' or 'Fêmea'
  final String? color;
  final String? parentMale;
  final String? parentFemale;
  final String? healthNotes;
  final String status; // 'Saudável', 'Doente', 'Botando', 'Não Botando'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Chicken({
    this.id,
    required this.name,
    required this.breed,
    required this.birthDate,
    this.photoPath,
    required this.sex,
    this.color,
    this.parentMale,
    this.parentFemale,
    this.healthNotes,
    this.status = 'Saudável',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Age calculation
  int get ageInDays {
    return DateTime.now().difference(birthDate).inDays;
  }

  int get ageInMonths {
    return (ageInDays / 30).floor();
  }

  int get ageInYears {
    return (ageInDays / 365).floor();
  }

  String get formattedAge {
    if (ageInYears > 0) {
      return '$ageInYears ano${ageInYears > 1 ? 's' : ''}';
    } else if (ageInMonths > 0) {
      return '$ageInMonths mês${ageInMonths > 1 ? 'es' : ''}';
    } else {
      return '$ageInDays dia${ageInDays > 1 ? 's' : ''}';
    }
  }

  bool get isLayingAge {
    return sex == 'Fêmea' && ageInMonths >= 5;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'birth_date': birthDate.toIso8601String(),
      'photo_path': photoPath,
      'sex': sex,
      'color': color,
      'parent_male': parentMale,
      'parent_female': parentFemale,
      'health_notes': healthNotes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map
  factory Chicken.fromMap(Map<String, dynamic> map) {
    return Chicken(
      id: map['id'] as int?,
      name: map['name'] as String,
      breed: map['breed'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      photoPath: map['photo_path'] as String?,
      sex: map['sex'] as String,
      color: map['color'] as String?,
      parentMale: map['parent_male'] as String?,
      parentFemale: map['parent_female'] as String?,
      healthNotes: map['health_notes'] as String?,
      status: map['status'] as String? ?? 'Saudável',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Copy with
  Chicken copyWith({
    int? id,
    String? name,
    String? breed,
    DateTime? birthDate,
    String? photoPath,
    String? sex,
    String? color,
    String? parentMale,
    String? parentFemale,
    String? healthNotes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chicken(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      photoPath: photoPath ?? this.photoPath,
      sex: sex ?? this.sex,
      color: color ?? this.color,
      parentMale: parentMale ?? this.parentMale,
      parentFemale: parentFemale ?? this.parentFemale,
      healthNotes: healthNotes ?? this.healthNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
