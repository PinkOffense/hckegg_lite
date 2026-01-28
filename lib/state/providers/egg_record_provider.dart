// lib/state/providers/egg_record_provider.dart

import 'package:flutter/material.dart';
import '../../core/date_utils.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/repositories/egg_repository.dart';
import '../../models/daily_egg_record.dart';

/// Provider para gestão de registos de ovos
class EggRecordProvider extends ChangeNotifier {
  final EggRepository _repository = RepositoryProvider.instance.eggRepository;

  List<DailyEggRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DailyEggRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas
  int get totalEggsCollected => _records.fold<int>(0, (sum, r) => sum + r.eggsCollected);
  int get totalEggsConsumed => _records.fold<int>(0, (sum, r) => sum + r.eggsConsumed);
  int get totalEggsRemaining => _records.fold<int>(0, (sum, r) => sum + r.eggsRemaining);

  /// Carregar todos os registos
  Future<void> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obter registo por data
  DailyEggRecord? getRecordByDate(String date) {
    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (e) {
      return null;
    }
  }

  /// Guardar (criar ou actualizar) um registo
  Future<void> saveRecord(DailyEggRecord record) async {
    try {
      final saved = await _repository.save(record);

      final existingIndex = _records.indexWhere((r) => r.date == saved.date);
      if (existingIndex != -1) {
        _records[existingIndex] = saved;
      } else {
        _records.insert(0, saved);
      }

      _records.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar um registo por data
  Future<void> deleteRecord(String date) async {
    try {
      await _repository.deleteByDate(date);
      _records.removeWhere((r) => r.date == date);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter registos num intervalo de datas
  List<DailyEggRecord> getRecordsInRange(DateTime start, DateTime end) {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Obter últimos N dias de registos
  List<DailyEggRecord> getRecentRecords(int days) {
    return _records.take(days).toList();
  }

  /// Pesquisar registos
  List<DailyEggRecord> search(String query) {
    if (query.isEmpty) return records;
    return records.where((r) {
      final notesMatch = r.notes?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final dateMatch = r.date.contains(query);
      return notesMatch || dateMatch;
    }).toList();
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _records = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
