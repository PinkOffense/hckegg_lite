// lib/state/providers/egg_provider.dart

import 'package:flutter/material.dart';
import '../../models/egg.dart';

/// Provider para gestão de ovos individuais (com tags e pesos)
///
/// Responsabilidades:
/// - Adicionar, editar e eliminar ovos individuais
/// - Fornecer lista de ovos
/// - Notificar listeners sobre mudanças de estado
///
/// Nota: Esta funcionalidade é armazenada localmente por enquanto
class EggProvider extends ChangeNotifier {
  List<Egg> _eggs = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Egg> get eggs => List.unmodifiable(_eggs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Próximo ID disponível
  int get nextId => _eggs.isEmpty ? 1 : (_eggs.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

  /// Adicionar um novo ovo
  void addEgg(Egg egg) {
    _error = null;
    _eggs.add(egg);
    notifyListeners();
  }

  /// Atualizar um ovo existente
  void updateEgg(Egg egg) {
    _error = null;
    final index = _eggs.indexWhere((e) => e.id == egg.id);
    if (index != -1) {
      _eggs[index] = egg;
      notifyListeners();
    }
  }

  /// Eliminar um ovo
  void deleteEgg(int id) {
    _error = null;
    _eggs.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Obter ovo por ID
  Egg? getEggById(int id) {
    try {
      return _eggs.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obter ovos por tag
  List<Egg> getEggsByTag(String tag) {
    return _eggs.where((e) => e.tag.toLowerCase().contains(tag.toLowerCase())).toList();
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _eggs = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
