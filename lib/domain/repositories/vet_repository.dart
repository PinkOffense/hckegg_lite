// lib/domain/repositories/vet_repository.dart

import '../../models/vet_record.dart';

/// Interface abstrata para o repositório de registos veterinários
abstract class VetRepository {
  /// Obter todos os registos veterinários do utilizador
  Future<List<VetRecord>> getAll();

  /// Obter registo por ID
  Future<VetRecord?> getById(String id);

  /// Obter registos por tipo
  Future<List<VetRecord>> getByType(VetRecordType type);

  /// Obter registos por gravidade
  Future<List<VetRecord>> getBySeverity(VetRecordSeverity severity);

  /// Obter acções agendadas futuras
  Future<List<VetRecord>> getUpcomingActions();

  /// Obter registos num intervalo de datas
  Future<List<VetRecord>> getByDateRange(DateTime start, DateTime end);

  /// Guardar (criar ou actualizar) um registo
  Future<VetRecord> save(VetRecord record);

  /// Eliminar um registo
  Future<void> delete(String id);

  /// Obter estatísticas veterinárias
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}
