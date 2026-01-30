import '../../../../core/core.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenses implements UseCase<List<Expense>, NoParams> {
  final ExpenseRepository repository;
  GetExpenses(this.repository);

  @override
  Future<Result<List<Expense>>> call(NoParams params) => repository.getExpenses();
}

class GetExpensesByCategory implements UseCase<List<Expense>, GetByCategoryParams> {
  final ExpenseRepository repository;
  GetExpensesByCategory(this.repository);

  @override
  Future<Result<List<Expense>>> call(GetByCategoryParams params) =>
      repository.getExpensesByCategory(params.category);
}

class GetByCategoryParams {
  final ExpenseCategory category;
  const GetByCategoryParams({required this.category});
}

class CreateExpense implements UseCase<Expense, CreateExpenseParams> {
  final ExpenseRepository repository;
  CreateExpense(this.repository);

  @override
  Future<Result<Expense>> call(CreateExpenseParams params) =>
      repository.createExpense(params.expense);
}

class CreateExpenseParams {
  final Expense expense;
  const CreateExpenseParams({required this.expense});
}

class UpdateExpense implements UseCase<Expense, UpdateExpenseParams> {
  final ExpenseRepository repository;
  UpdateExpense(this.repository);

  @override
  Future<Result<Expense>> call(UpdateExpenseParams params) =>
      repository.updateExpense(params.expense);
}

class UpdateExpenseParams {
  final Expense expense;
  const UpdateExpenseParams({required this.expense});
}

class DeleteExpense implements UseCase<void, DeleteExpenseParams> {
  final ExpenseRepository repository;
  DeleteExpense(this.repository);

  @override
  Future<Result<void>> call(DeleteExpenseParams params) =>
      repository.deleteExpense(params.id);
}

class DeleteExpenseParams {
  final String id;
  const DeleteExpenseParams({required this.id});
}
