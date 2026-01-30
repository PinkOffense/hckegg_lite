import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.date,
    required super.category,
    required super.amount,
    required super.description,
    super.notes,
    required super.createdAt,
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      date: entity.date,
      category: entity.category,
      amount: entity.amount,
      description: entity.description,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      date: json['date'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'category': category.name,
      'amount': amount,
      'description': description,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'date': date,
      'category': category.name,
      'amount': amount,
      'description': description,
      'notes': notes,
    };
  }

  Expense toEntity() => this;
}
