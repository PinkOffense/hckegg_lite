// lib/data/repositories/sale_repository_impl.dart

import '../../domain/repositories/sale_repository.dart';
import '../../models/egg_sale.dart';
import '../datasources/remote/sale_remote_datasource.dart';

/// Implementação do SaleRepository usando Supabase
class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDatasource _remoteDatasource;

  SaleRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<EggSale>> getAll() async {
    try {
      return await _remoteDatasource.getAll();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<EggSale?> getById(String id) async {
    try {
      return await _remoteDatasource.getById(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<EggSale>> getByDateRange(DateTime start, DateTime end) async {
    try {
      return await _remoteDatasource.getByDateRange(start, end);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<EggSale>> getByCustomer(String customerName) async {
    try {
      return await _remoteDatasource.getByCustomer(customerName);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<EggSale> save(EggSale sale) async {
    try {
      // Verificar se já existe
      final existing = await _remoteDatasource.getById(sale.id);

      if (existing != null) {
        // Actualizar
        return await _remoteDatasource.update(sale);
      } else {
        // Criar
        return await _remoteDatasource.create(sale);
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
  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _remoteDatasource.getTotalRevenue(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSalesStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _remoteDatasource.getSalesStatistics(
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
