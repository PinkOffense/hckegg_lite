// lib/state/providers/sale_provider.dart

import 'package:flutter/material.dart';
import '../../core/date_utils.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../models/egg_sale.dart';

/// Provider para gestão de vendas
///
/// Responsabilidades:
/// - Carregar, guardar e eliminar vendas
/// - Fornecer estatísticas de vendas
/// - Notificar listeners sobre mudanças de estado
class SaleProvider extends ChangeNotifier {
  final SaleRepository _repository;

  /// Construtor que permite injecção de dependências para testes
  SaleProvider({SaleRepository? repository})
      : _repository = repository ?? RepositoryProvider.instance.saleRepository;

  List<EggSale> _sales = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EggSale> get sales => List.unmodifiable(_sales);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas
  int get totalEggsSold => _sales.fold<int>(0, (sum, s) => sum + s.quantitySold);
  double get totalRevenue => _sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);

  /// Carregar todas as vendas
  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guardar uma venda
  Future<void> saveSale(EggSale sale) async {
    try {
      final saved = await _repository.save(sale);

      final existingIndex = _sales.indexWhere((s) => s.id == saved.id);
      if (existingIndex != -1) {
        _sales[existingIndex] = saved;
      } else {
        _sales.insert(0, saved);
      }

      _sales.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar uma venda
  Future<void> deleteSale(String id) async {
    try {
      await _repository.delete(id);
      _sales.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter vendas num intervalo de datas
  List<EggSale> getSalesInRange(DateTime start, DateTime end) {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _sales.where((s) {
      return s.date.compareTo(startStr) >= 0 && s.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Obter vendas por cliente
  List<EggSale> getSalesByCustomer(String customerName) {
    return _sales.where((s) =>
      s.customerName?.toLowerCase().contains(customerName.toLowerCase()) ?? false
    ).toList();
  }

  /// Obter últimas N vendas
  List<EggSale> getRecentSales(int count) {
    return _sales.take(count).toList();
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _sales = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
