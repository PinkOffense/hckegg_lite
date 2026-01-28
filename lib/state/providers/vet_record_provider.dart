// lib/state/providers/vet_record_provider.dart

import 'package:flutter/material.dart';
import '../../core/date_utils.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/repositories/vet_repository.dart';
import '../../models/vet_record.dart';

/// Provider para gestão de registos veterinários
///
/// Responsabilidades:
/// - Carregar, guardar e eliminar registos veterinários
/// - Fornecer estatísticas de saúde
/// - Gerir agendamentos e lembretes
/// - Notificar listeners sobre mudanças de estado
class VetRecordProvider extends ChangeNotifier {
  final VetRepository _repository;

  /// Construtor que permite injecção de dependências para testes
  VetRecordProvider({VetRepository? repository})
      : _repository = repository ?? RepositoryProvider.instance.vetRepository;

  List<VetRecord> _vetRecords = [];
  bool _isLoading = false;
  String? _error;

  // Cached statistics
  int? _cachedTotalDeaths;
  double? _cachedTotalCosts;
  int? _cachedTotalHensAffected;

  // Getters
  List<VetRecord> get vetRecords => List.unmodifiable(_vetRecords);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas (cached for performance)
  int get totalVetRecords => _vetRecords.length;

  int get totalDeaths {
    _cachedTotalDeaths ??= _vetRecords.where((r) => r.type == VetRecordType.death).length;
    return _cachedTotalDeaths!;
  }

  double get totalVetCosts {
    _cachedTotalCosts ??= _vetRecords.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0));
    return _cachedTotalCosts!;
  }

  int get totalHensAffected {
    _cachedTotalHensAffected ??= _vetRecords.fold<int>(0, (sum, r) => sum + r.hensAffected);
    return _cachedTotalHensAffected!;
  }

  void _invalidateCache() {
    _cachedTotalDeaths = null;
    _cachedTotalCosts = null;
    _cachedTotalHensAffected = null;
  }

  /// Carregar registos veterinários
  Future<void> loadVetRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vetRecords = await _repository.getAll();
      await _cleanupPastAppointments();
      _invalidateCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove appointments scheduled for before today
  Future<void> _cleanupPastAppointments() async {
    final todayStr = AppDateUtils.toIsoDateString(DateTime.now());

    final pastRecords = _vetRecords.where((r) {
      if (r.nextActionDate == null) return false;
      return r.nextActionDate!.compareTo(todayStr) < 0;
    }).toList();

    for (final record in pastRecords) {
      try {
        await _repository.delete(record.id);
        _vetRecords.removeWhere((r) => r.id == record.id);
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  }

  /// Get today's appointments for reminder popup
  List<VetRecord> getTodayAppointments() {
    final todayStr = AppDateUtils.toIsoDateString(DateTime.now());
    return _vetRecords
        .where((r) => r.nextActionDate == todayStr)
        .toList();
  }

  /// Obter registos veterinários (ordenados)
  List<VetRecord> getVetRecords() {
    final sorted = List<VetRecord>.from(_vetRecords);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Guardar um registo veterinário
  ///
  /// Throws [ArgumentError] if:
  /// - hensAffected is negative
  /// - date is empty
  /// - description is empty
  /// - cost is negative (when provided)
  Future<void> saveVetRecord(VetRecord record) async {
    _validateVetRecord(record);

    try {
      final saved = await _repository.save(record);

      final existingIndex = _vetRecords.indexWhere((r) => r.id == saved.id);
      if (existingIndex != -1) {
        _vetRecords[existingIndex] = saved;
      } else {
        _vetRecords.add(saved);
      }

      _invalidateCache();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Validates vet record data before saving
  void _validateVetRecord(VetRecord record) {
    if (record.hensAffected < 0) {
      throw ArgumentError('Hens affected cannot be negative');
    }
    if (record.date.isEmpty) {
      throw ArgumentError('Record date cannot be empty');
    }
    if (record.description.isEmpty) {
      throw ArgumentError('Record description cannot be empty');
    }
    if (record.cost != null && record.cost! < 0) {
      throw ArgumentError('Cost cannot be negative');
    }
  }

  /// Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Eliminar um registo veterinário
  Future<void> deleteVetRecord(String id) async {
    try {
      await _repository.delete(id);
      _vetRecords.removeWhere((r) => r.id == id);
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter registos por tipo
  List<VetRecord> getVetRecordsByType(VetRecordType type) {
    return _vetRecords.where((r) => r.type == type).toList();
  }

  /// Obter acções agendadas futuras
  List<VetRecord> getUpcomingVetActions() {
    final now = DateTime.now();
    return _vetRecords
        .where((r) => r.nextActionDate != null)
        .where((r) {
          final nextDate = DateTime.parse(r.nextActionDate!);
          return nextDate.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a.nextActionDate!.compareTo(b.nextActionDate!));
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _vetRecords = [];
    _error = null;
    _isLoading = false;
    _invalidateCache();
    notifyListeners();
  }
}
