// lib/domain/repositories/egg_repository.dart

import '../../models/daily_egg_record.dart';

/// Interface abstrata para o repositório de registos de ovos
/// Define o contrato que as implementações devem seguir
abstract class EggRepository {
  /// Obter todos os registos do utilizador
  Future<List<DailyEggRecord>> getAll();

  /// Obter registo por data específica
  Future<DailyEggRecord?> getByDate(String date);

  /// Obter registos num intervalo de datas
  Future<List<DailyEggRecord>> getByDateRange(DateTime start, DateTime end);

  /// Obter os últimos N registos
  Future<List<DailyEggRecord>> getRecent(int count);

  /// Guardar (criar ou actualizar) um registo
  Future<DailyEggRecord> save(DailyEggRecord record);

  /// Eliminar um registo por data
  Future<void> deleteByDate(String date);

  /// Eliminar um registo por ID
  Future<void> deleteById(String id);

  /// Pesquisar registos (por notas ou data)
  Future<List<DailyEggRecord>> search(String query);

  /// Obter estatísticas do utilizador
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}
