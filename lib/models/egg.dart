class Egg {
  final int? id;
  final int chickenId;
  final DateTime layDate;
  final int quantity;
  final String? notes;
  final bool isClutch;
  final DateTime? expectedHatchDate;
  final DateTime createdAt;

  Egg({
    this.id,
    required this.chickenId,
    required this.layDate,
    this.quantity = 1,
    this.notes,
    this.isClutch = false,
    this.expectedHatchDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Expected hatch date calculation (21 days for chickens)
  DateTime get calculatedHatchDate {
    return layDate.add(const Duration(days: 21));
  }

  bool get isHatching {
    if (!isClutch) return false;
    final now = DateTime.now();
    final hatchDate = expectedHatchDate ?? calculatedHatchDate;
    return now.isAfter(hatchDate.subtract(const Duration(days: 3))) &&
        now.isBefore(hatchDate.add(const Duration(days: 3)));
  }

  int get daysUntilHatch {
    if (!isClutch) return 0;
    final hatchDate = expectedHatchDate ?? calculatedHatchDate;
    return hatchDate.difference(DateTime.now()).inDays;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chicken_id': chickenId,
      'lay_date': layDate.toIso8601String(),
      'quantity': quantity,
      'notes': notes,
      'is_clutch': isClutch ? 1 : 0,
      'expected_hatch_date': expectedHatchDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Egg.fromMap(Map<String, dynamic> map) {
    return Egg(
      id: map['id'] as int?,
      chickenId: map['chicken_id'] as int,
      layDate: DateTime.parse(map['lay_date'] as String),
      quantity: map['quantity'] as int? ?? 1,
      notes: map['notes'] as String?,
      isClutch: (map['is_clutch'] as int? ?? 0) == 1,
      expectedHatchDate: map['expected_hatch_date'] != null
          ? DateTime.parse(map['expected_hatch_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Copy with
  Egg copyWith({
    int? id,
    int? chickenId,
    DateTime? layDate,
    int? quantity,
    String? notes,
    bool? isClutch,
    DateTime? expectedHatchDate,
    DateTime? createdAt,
  }) {
    return Egg(
      id: id ?? this.id,
      chickenId: chickenId ?? this.chickenId,
      layDate: layDate ?? this.layDate,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      isClutch: isClutch ?? this.isClutch,
      expectedHatchDate: expectedHatchDate ?? this.expectedHatchDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
