import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../../lib/core/core.dart';
import '../../../../lib/features/expenses/data/repositories/expense_repository_impl.dart';
import '../../../../lib/features/expenses/domain/entities/expense.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _getExpense(context, id),
    HttpMethod.put => _updateExpense(context, id),
    HttpMethod.delete => _deleteExpense(context, id),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getExpense(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = ExpenseRepositoryImpl(SupabaseClientManager.client);
    final result = await repository.getExpenseById(id);

    return result.fold(
      onSuccess: (expense) => expense.userId != userId
          ? Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'})
          : Response.json(body: {'data': expense.toJson()}),
      onFailure: (f) => Response.json(statusCode: f is NotFoundFailure ? HttpStatus.notFound : HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _updateExpense(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = ExpenseRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getExpenseById(id);
    final existingExpense = existing.valueOrNull;
    if (existingExpense == null) return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Not found'});
    if (existingExpense.userId != userId) return Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'});

    final body = await context.request.json() as Map<String, dynamic>;
    final updated = Expense(
      id: id,
      userId: existingExpense.userId,
      date: (body['date'] as String?) ?? existingExpense.date,
      category: body['category'] != null ? ExpenseCategory.fromString(body['category'] as String) : existingExpense.category,
      amount: (body['amount'] as num?)?.toDouble() ?? existingExpense.amount,
      description: (body['description'] as String?) ?? existingExpense.description,
      notes: body['notes'] as String? ?? existingExpense.notes,
      createdAt: existingExpense.createdAt,
    );

    final result = await repository.updateExpense(updated);
    return result.fold(
      onSuccess: (e) => Response.json(body: {'data': e.toJson()}),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}

Future<Response> _deleteExpense(RequestContext context, String id) async {
  try {
    final userId = AuthUtils.getUserIdFromContext(context);
    if (userId == null) return Response.json(statusCode: HttpStatus.unauthorized, body: {'error': 'Unauthorized'});

    final repository = ExpenseRepositoryImpl(SupabaseClientManager.client);
    final existing = await repository.getExpenseById(id);
    final existingExpense = existing.valueOrNull;
    if (existingExpense == null) return Response.json(statusCode: HttpStatus.notFound, body: {'error': 'Not found'});
    if (existingExpense.userId != userId) return Response.json(statusCode: HttpStatus.forbidden, body: {'error': 'Access denied'});

    final result = await repository.deleteExpense(id);
    return result.fold(
      onSuccess: (_) => Response(statusCode: HttpStatus.noContent),
      onFailure: (f) => Response.json(statusCode: HttpStatus.internalServerError, body: {'error': f.message}),
    );
  } catch (e) {
    return Response.json(statusCode: HttpStatus.internalServerError, body: {'error': e.toString()});
  }
}
