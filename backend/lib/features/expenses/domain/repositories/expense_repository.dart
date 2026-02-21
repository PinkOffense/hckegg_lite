import '../../../../core/core.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Result<List<Expense>>> getExpenses(String userId, {String? farmId});
  Future<Result<Expense>> getExpenseById(String id);
  Future<Result<List<Expense>>> getExpensesInRange(String userId, String startDate, String endDate, {String? farmId});
  Future<Result<List<Expense>>> getExpensesByCategory(String userId, ExpenseCategory category, {String? farmId});
  Future<Result<Expense>> createExpense(Expense expense);
  Future<Result<Expense>> updateExpense(Expense expense);
  Future<Result<void>> deleteExpense(String id);
  Future<Result<ExpenseStatistics>> getStatistics(String userId, String startDate, String endDate, {String? farmId});
}

class ExpenseStatistics {
  const ExpenseStatistics({
    required this.totalExpenses,
    required this.totalAmount,
    required this.byCategory,
  });

  final int totalExpenses;
  final double totalAmount;
  final Map<String, double> byCategory;

  Map<String, dynamic> toJson() => {
        'total_expenses': totalExpenses,
        'total_amount': totalAmount,
        'by_category': byCategory,
      };
}
