import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  feed,
  maintenance,
  equipment,
  utilities,
  other;

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.userId,
    this.farmId,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? farmId;
  final String date;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'farm_id': farmId,
        'date': date,
        'category': category.name,
        'amount': amount,
        'description': description,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        farmId: json['farm_id'] as String?,
        date: json['date'] as String,
        category: ExpenseCategory.fromString(json['category'] as String),
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, date, category, amount];
}
