// lib/data/repositories/vet_repository_impl.dart

import '../../domain/repositories/vet_repository.dart';
import '../../models/vet_record.dart';
import '../datasources/remote/vet_remote_datasource.dart';

/// Implementação do VetRepository usando Supabase
class VetRepositoryImpl implements VetRepository {
  final VetRemoteDatasource _remoteDatasource;

  VetRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<VetRecord>> getAll() async {
    try {
      return await _remoteDatasource.getAll();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<VetRecord?> getById(String id) async {
    try {
      return await _remoteDatasource.getById(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<VetRecord>> getByType(VetRecordType type) async {
    try {
      return await _remoteDatasource.getByType(type);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<VetRecord>> getBySeverity(VetRecordSeverity severity) async {
    try {
      return await _remoteDatasource.getBySeverity(severity);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<VetRecord>> getUpcomingActions() async {
    try {
      return await _remoteDatasource.getUpcomingActions();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<VetRecord>> getByDateRange(DateTime start, DateTime end) async {
    try {
      return await _remoteDatasource.getByDateRange(start, end);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<VetRecord> save(VetRecord record) async {
    try {
      // Verificar se já existe
      final existing = await _remoteDatasource.getById(record.id);

      if (existing != null) {
        // Actualizar
        return await _remoteDatasource.update(record);
      } else {
        // Criar
        return await _remoteDatasource.create(record);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _remoteDatasource.delete(id);
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
    if (error.toString().contains('Database error')) {
      return Exception('Database error: $error');
    }
    return Exception('Unexpected error: $error');
  }
}
