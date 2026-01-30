import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  feed,
  maintenance,
  equipment,
  utilities,
  other;

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

class Expense extends Equatable {
  final String id;
  final String date;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String? notes;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.notes,
    required this.createdAt,
  });

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

  @override
  List<Object?> get props => [id, date, category, amount, description, notes, createdAt];
}
