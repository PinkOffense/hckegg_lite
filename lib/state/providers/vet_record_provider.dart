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

  // Getters
  List<VetRecord> get vetRecords => List.unmodifiable(_vetRecords);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estatísticas
  int get totalVetRecords => _vetRecords.length;
  int get totalDeaths => _vetRecords.where((r) => r.type == VetRecordType.death).length;
  double get totalVetCosts => _vetRecords.fold<double>(0.0, (sum, r) => sum + (r.cost ?? 0.0));
  int get totalHensAffected => _vetRecords.fold<int>(0, (sum, r) => sum + r.hensAffected);

  /// Carregar registos veterinários
  Future<void> loadVetRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vetRecords = await _repository.getAll();
      await _cleanupPastAppointments();
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
  Future<void> saveVetRecord(VetRecord record) async {
    try {
      final saved = await _repository.save(record);

      final existingIndex = _vetRecords.indexWhere((r) => r.id == saved.id);
      if (existingIndex != -1) {
        _vetRecords[existingIndex] = saved;
      } else {
        _vetRecords.add(saved);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar um registo veterinário
  Future<void> deleteVetRecord(String id) async {
    try {
      await _repository.delete(id);
      _vetRecords.removeWhere((r) => r.id == id);
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
    notifyListeners();
  }
}
