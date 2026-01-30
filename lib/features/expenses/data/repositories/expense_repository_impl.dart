import '../../../../core/core.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Expense>>> getExpenses() async {
    try {
      final expenses = await remoteDataSource.getExpenses();
      return Success(expenses.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Expense>> getExpenseById(String id) async {
    try {
      final expense = await remoteDataSource.getExpenseById(id);
      return Success(expense.toEntity());
    } catch (e) {
      return Fail(NotFoundFailure(message: 'Expense not found'));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpensesByDateRange({required String startDate, required String endDate}) async {
    try {
      final expenses = await remoteDataSource.getExpensesByDateRange(startDate: startDate, endDate: endDate);
      return Success(expenses.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpensesByCategory(ExpenseCategory category) async {
    try {
      final expenses = await remoteDataSource.getExpensesByCategory(category);
      return Success(expenses.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Expense>> createExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      final created = await remoteDataSource.createExpense(model);
      return Success(created.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Expense>> updateExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      final updated = await remoteDataSource.updateExpense(model);
      return Success(updated.toEntity());
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String id) async {
    try {
      await remoteDataSource.deleteExpense(id);
      return const Success(null);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<double>> getTotalExpenses({required String startDate, required String endDate}) async {
    try {
      final expenses = await remoteDataSource.getExpensesByDateRange(startDate: startDate, endDate: endDate);
      final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      return Success(total);
    } catch (e) {
      return Fail(ServerFailure(message: e.toString()));
    }
  }
}
