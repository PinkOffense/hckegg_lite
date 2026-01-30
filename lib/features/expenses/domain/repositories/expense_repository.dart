import '../../../../core/core.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Result<List<Expense>>> getExpenses();
  Future<Result<Expense>> getExpenseById(String id);
  Future<Result<List<Expense>>> getExpensesByDateRange({required String startDate, required String endDate});
  Future<Result<List<Expense>>> getExpensesByCategory(ExpenseCategory category);
  Future<Result<Expense>> createExpense(Expense expense);
  Future<Result<Expense>> updateExpense(Expense expense);
  Future<Result<void>> deleteExpense(String id);
  Future<Result<double>> getTotalExpenses({required String startDate, required String endDate});
}
