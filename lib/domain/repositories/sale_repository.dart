// lib/domain/repositories/sale_repository.dart

import '../../models/egg_sale.dart';

/// Interface abstrata para o repositório de vendas de ovos
abstract class SaleRepository {
  /// Obter todas as vendas do utilizador
  Future<List<EggSale>> getAll();

  /// Obter venda por ID
  Future<EggSale?> getById(String id);

  /// Obter vendas num intervalo de datas
  Future<List<EggSale>> getByDateRange(DateTime start, DateTime end);

  /// Obter vendas por cliente
  Future<List<EggSale>> getByCustomer(String customerName);

  /// Guardar (criar ou actualizar) uma venda
  Future<EggSale> save(EggSale sale);

  /// Eliminar uma venda
  Future<void> delete(String id);

  /// Obter receita total
  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obter estatísticas de vendas
  Future<Map<String, dynamic>> getSalesStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}
