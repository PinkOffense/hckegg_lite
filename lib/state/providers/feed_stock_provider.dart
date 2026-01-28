// lib/state/providers/feed_stock_provider.dart

import 'package:flutter/material.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../models/feed_stock.dart';

/// Provider para gestão de stocks de ração
///
/// Responsabilidades:
/// - Carregar, guardar e eliminar stocks de ração
/// - Gerir movimentos de stock (compras, consumo)
/// - Alertar sobre stocks baixos
/// - Notificar listeners sobre mudanças de estado
class FeedStockProvider extends ChangeNotifier {
  final FeedRepository _repository;

  /// Construtor que permite injecção de dependências para testes
  FeedStockProvider({FeedRepository? repository})
      : _repository = repository ?? RepositoryProvider.instance.feedRepository;

  List<FeedStock> _feedStocks = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<FeedStock> get feedStocks => List.unmodifiable(_feedStocks);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas
  double get totalFeedStock => _feedStocks.fold<double>(0.0, (sum, s) => sum + s.currentQuantityKg);
  int get lowStockCount => _feedStocks.where((s) => s.isLowStock).length;

  /// Carregar todos os stocks de ração
  Future<void> loadFeedStocks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedStocks = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obter todos os stocks de ração
  List<FeedStock> getFeedStocks() {
    return List<FeedStock>.from(_feedStocks);
  }

  /// Obter stocks com quantidade baixa
  List<FeedStock> getLowStockFeeds() {
    return _feedStocks.where((s) => s.isLowStock).toList();
  }

  /// Guardar um stock de ração
  Future<void> saveFeedStock(FeedStock stock) async {
    // Optimistic update
    final existingIndex = _feedStocks.indexWhere((s) => s.id == stock.id);
    if (existingIndex != -1) {
      _feedStocks[existingIndex] = stock;
    } else {
      _feedStocks.add(stock);
    }
    notifyListeners();

    try {
      await _repository.save(stock);
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Eliminar um stock de ração
  Future<void> deleteFeedStock(String id) async {
    try {
      await _repository.delete(id);
      _feedStocks.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Adicionar movimento de stock (compra, consumo, etc)
  Future<void> addFeedMovement(FeedMovement movement, FeedStock stock) async {
    double newQuantity = stock.currentQuantityKg;
    if (movement.movementType == StockMovementType.purchase) {
      newQuantity += movement.quantityKg;
    } else {
      newQuantity -= movement.quantityKg;
    }

    final updatedStock = stock.copyWith(
      currentQuantityKg: newQuantity < 0 ? 0 : newQuantity,
      lastUpdated: DateTime.now(),
    );

    // Optimistic update
    final existingIndex = _feedStocks.indexWhere((s) => s.id == stock.id);
    if (existingIndex != -1) {
      _feedStocks[existingIndex] = updatedStock;
      notifyListeners();
    }

    try {
      await _repository.addMovement(movement);
      await _repository.save(updatedStock);
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Obter movimentos de um stock
  Future<List<FeedMovement>> getFeedMovements(String feedStockId) async {
    try {
      return await _repository.getMovements(feedStockId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _feedStocks = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
