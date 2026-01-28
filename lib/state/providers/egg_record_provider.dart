// lib/state/providers/egg_record_provider.dart

import 'package:flutter/material.dart';
import '../../core/date_utils.dart';
import '../../core/di/repository_provider.dart';
import '../../core/models/week_stats.dart';
import '../../domain/repositories/egg_repository.dart';
import '../../models/daily_egg_record.dart';
import '../../models/egg_sale.dart';
import '../../models/expense.dart';

/// Provider para gestão de registos de ovos
///
/// Responsabilidades:
/// - Carregar, guardar e eliminar registos de ovos
/// - Fornecer estatísticas agregadas
/// - Notificar listeners sobre mudanças de estado
class EggRecordProvider extends ChangeNotifier {
  final EggRepository _repository;

  List<DailyEggRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  // Cached statistics (invalidated on data changes)
  int? _cachedTotalCollected;
  int? _cachedTotalConsumed;
  int? _cachedTotalRemaining;

  /// Construtor que permite injecção de dependências para testes
  EggRecordProvider({EggRepository? repository})
      : _repository = repository ?? RepositoryProvider.instance.eggRepository;

  // ============== Getters ==============

  /// Lista imutável de registos
  List<DailyEggRecord> get records => List.unmodifiable(_records);

  /// Indica se está a carregar dados
  bool get isLoading => _isLoading;

  /// Mensagem de erro, se existir
  String? get error => _error;

  /// Limpa o erro atual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============== Estatísticas (cached for performance) ==============

  /// Total de ovos recolhidos (todos os registos)
  int get totalEggsCollected {
    _cachedTotalCollected ??= _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
    return _cachedTotalCollected!;
  }

  /// Total de ovos consumidos (todos os registos)
  int get totalEggsConsumed {
    _cachedTotalConsumed ??= _records.fold<int>(0, (sum, r) => sum + r.eggsConsumed);
    return _cachedTotalConsumed!;
  }

  /// Total de ovos restantes (todos os registos)
  int get totalEggsRemaining {
    _cachedTotalRemaining ??= _records.fold<int>(0, (sum, r) => sum + r.eggsRemaining);
    return _cachedTotalRemaining!;
  }

  /// Número total de registos
  int get recordCount => _records.length;

  /// Invalidate cached statistics when data changes
  void _invalidateCache() {
    _cachedTotalCollected = null;
    _cachedTotalConsumed = null;
    _cachedTotalRemaining = null;
  }

  // ============== CRUD Operations ==============

  /// Carrega todos os registos do repositório
  ///
  /// Retorna `true` se a operação foi bem sucedida
  Future<bool> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _repository.getAll();
      _records.sort((a, b) => b.date.compareTo(a.date));
      _invalidateCache();
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtém um registo por data
  ///
  /// [date] deve estar no formato ISO (YYYY-MM-DD)
  /// Retorna `null` se não encontrar
  DailyEggRecord? getRecordByDate(String date) {
    if (date.isEmpty) return null;

    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  /// Guarda (cria ou actualiza) um registo
  ///
  /// Throws em caso de erro
  Future<void> saveRecord(DailyEggRecord record) async {
    _validateRecord(record);

    try {
      final saved = await _repository.save(record);

      final existingIndex = _records.indexWhere((r) => r.date == saved.date);
      if (existingIndex != -1) {
        _records[existingIndex] = saved;
      } else {
        _records.insert(0, saved);
      }

      _records.sort((a, b) => b.date.compareTo(a.date));
      _invalidateCache();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Elimina um registo por data
  ///
  /// [date] deve estar no formato ISO (YYYY-MM-DD)
  Future<void> deleteRecord(String date) async {
    if (date.isEmpty) {
      throw ArgumentError('Data não pode estar vazia');
    }

    try {
      await _repository.deleteByDate(date);
      _records.removeWhere((r) => r.date == date);
      _invalidateCache();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  // ============== Queries ==============

  /// Obtém registos num intervalo de datas
  List<DailyEggRecord> getRecordsInRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      return [];
    }

    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Obtém os últimos N registos
  ///
  /// [count] deve ser positivo
  List<DailyEggRecord> getRecentRecords(int count) {
    if (count <= 0) return [];
    return _records.take(count).toList();
  }

  /// Pesquisa registos por texto (data ou notas)
  List<DailyEggRecord> search(String query) {
    if (query.isEmpty) return List.unmodifiable(_records);

    final normalizedQuery = query.toLowerCase().trim();

    return _records.where((r) {
      final notesMatch = r.notes?.toLowerCase().contains(normalizedQuery) ?? false;
      final dateMatch = r.date.contains(query);
      return notesMatch || dateMatch;
    }).toList();
  }

  // ============== Estatísticas Avançadas ==============

  /// Calcula estatísticas da semana actual
  ///
  /// [sales] - Lista de vendas para calcular receita
  /// [expenses] - Lista de despesas para calcular custos
  WeekStats getWeekStats({
    required List<EggSale> sales,
    required List<Expense> expenses,
  }) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startStr = AppDateUtils.toIsoDateString(startOfWeek);
    final endStr = AppDateUtils.toIsoDateString(endOfWeek);

    // Filtrar registos da semana
    final weekRecords = _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    });

    // Calcular estatísticas de ovos
    int collected = 0;
    int consumed = 0;
    for (final record in weekRecords) {
      collected += record.eggsCollected;
      consumed += record.eggsConsumed;
    }

    // Calcular estatísticas de vendas
    int sold = 0;
    double revenue = 0.0;
    for (final sale in sales) {
      if (sale.date.compareTo(startStr) >= 0 && sale.date.compareTo(endStr) <= 0) {
        sold += sale.quantitySold;
        revenue += sale.totalAmount;
      }
    }

    // Calcular despesas
    double expensesTotal = 0.0;
    for (final expense in expenses) {
      if (expense.date.compareTo(startStr) >= 0 && expense.date.compareTo(endStr) <= 0) {
        expensesTotal += expense.amount;
      }
    }

    return WeekStats(
      collected: collected,
      consumed: consumed,
      sold: sold,
      revenue: revenue,
      expenses: expensesTotal,
      netProfit: revenue - expensesTotal,
    );
  }

  // ============== Lifecycle ==============

  /// Limpa todos os dados locais (usado no logout)
  void clearData() {
    _records = [];
    _error = null;
    _isLoading = false;
    _invalidateCache();
    notifyListeners();
  }

  // ============== Private Helpers ==============

  /// Valida um registo antes de guardar
  void _validateRecord(DailyEggRecord record) {
    if (record.eggsCollected < 0) {
      throw ArgumentError('Número de ovos recolhidos não pode ser negativo');
    }
    if (record.eggsConsumed < 0) {
      throw ArgumentError('Número de ovos consumidos não pode ser negativo');
    }
    if (record.date.isEmpty) {
      throw ArgumentError('Data não pode estar vazia');
    }
  }

  /// Formata erros para apresentação
  String _formatError(dynamic error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Erro de validação';
    }
    return error.toString();
  }
}
