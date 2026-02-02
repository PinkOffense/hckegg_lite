import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/expenses/data/repositories/expense_repository_impl.dart';
import '../../../../lib/features/expenses/domain/entities/expense.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getExpenses(context),
    HttpMethod.post => _createExpense(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getExpenses(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = ExpenseRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getExpenses(userId);

    return result.fold(
      onSuccess: (expenses) => Response.json(body: {'data': expenses.map((e) => e.toJson()).toList(), 'count': expenses.length}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _createExpense(RequestContext context) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final body = await context.request.json() as Map<String, dynamic>;
    final expense = Expense(
      id: '',
      userId: userId,
      date: body['date'] as String,
      category: ExpenseCategory.fromString(body['category'] as String),
      amount: (body['amount'] as num).toDouble(),
      description: body['description'] as String,
      notes: body['notes'] as String?,
      createdAt: DateTime.now().toUtc(),
    );

    final repository = ExpenseRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.createExpense(expense);

    return result.fold(
      onSuccess: (e) => Response.json(statusCode: HttpStatus.created, body: {'data': e.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
