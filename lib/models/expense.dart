// lib/models/expense.dart

enum ExpenseCategory {
  feed,
  maintenance,
  equipment,
  utilities,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String displayName(String locale) {
    switch (this) {
      case ExpenseCategory.feed:
        return locale == 'pt' ? 'Ração' : 'Feed';
      case ExpenseCategory.maintenance:
        return locale == 'pt' ? 'Manutenção' : 'Maintenance';
      case ExpenseCategory.equipment:
        return locale == 'pt' ? 'Equipamento' : 'Equipment';
      case ExpenseCategory.utilities:
        return locale == 'pt' ? 'Utilidades' : 'Utilities';
      case ExpenseCategory.other:
        return locale == 'pt' ? 'Outros' : 'Other';
    }
  }
}

class Expense {
  final String id;
  final String date;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String? notes;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'category': category.name,
      'amount': amount,
      'description': description,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: json['date'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Expense copyWith({
    String? id,
    String? date,
    ExpenseCategory? category,
    double? amount,
    String? description,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
