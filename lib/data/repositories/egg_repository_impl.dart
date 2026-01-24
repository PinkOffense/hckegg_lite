// lib/data/repositories/egg_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/egg_repository.dart';
import '../../models/daily_egg_record.dart';
import '../datasources/remote/egg_remote_datasource.dart';

/// Implementação do EggRepository usando Supabase
class EggRepositoryImpl implements EggRepository {
  final EggRemoteDatasource _remoteDatasource;

  EggRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<DailyEggRecord>> getAll() async {
    try {
      return await _remoteDatasource.getAll();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<DailyEggRecord?> getByDate(String date) async {
    try {
      return await _remoteDatasource.getByDate(date);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<DailyEggRecord>> getByDateRange(DateTime start, DateTime end) async {
    try {
      return await _remoteDatasource.getByDateRange(start, end);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<DailyEggRecord>> getRecent(int count) async {
    try {
      return await _remoteDatasource.getRecent(count);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<DailyEggRecord> save(DailyEggRecord record) async {
    try {
      // Verificar se já existe um registo para esta data
      final existing = await _remoteDatasource.getByDate(record.date);

      if (existing != null) {
        // Actualizar registo existente
        return await _remoteDatasource.update(record.copyWith(id: existing.id));
      } else {
        // Criar novo registo
        return await _remoteDatasource.create(record);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteByDate(String date) async {
    try {
      await _remoteDatasource.deleteByDate(date);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteById(String id) async {
    try {
      await _remoteDatasource.deleteById(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<DailyEggRecord>> search(String query) async {
    try {
      return await _remoteDatasource.search(query);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _remoteDatasource.getStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Tratamento de erros centralizado
  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      return Exception('Database error: ${error.message}');
    }
    return Exception('Unexpected error: $error');
  }
}
