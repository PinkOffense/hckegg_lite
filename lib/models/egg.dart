class Egg {
  final int id;
  final String tag;
  final DateTime createdAt;
  final int? weight;
  final bool synced;

  Egg({
    required this.id,
    required this.tag,
    required this.createdAt,
    this.weight,
    this.synced = false,
  });

  Egg copyWith({int? id, String? tag, DateTime? createdAt, int? weight, bool? synced}) {
    return Egg(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      weight: weight ?? this.weight,
      synced: synced ?? this.synced,
    );
  }
}
