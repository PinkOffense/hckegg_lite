// lib/core/models/week_stats.dart

/// Classe imutável para estatísticas semanais
/// Segue o princípio de imutabilidade para maior segurança
class WeekStats {
  final int collected;
  final int consumed;
  final int sold;
  final double revenue;
  final double expenses;
  final double netProfit;

  const WeekStats({
    required this.collected,
    required this.consumed,
    required this.sold,
    required this.revenue,
    required this.expenses,
    required this.netProfit,
  });

  /// Cria uma instância vazia (valores zero)
  const WeekStats.empty()
      : collected = 0,
        consumed = 0,
        sold = 0,
        revenue = 0.0,
        expenses = 0.0,
        netProfit = 0.0;

  /// Verifica se há lucro
  bool get hasProfit => netProfit > 0;

  /// Verifica se há prejuízo
  bool get hasLoss => netProfit < 0;

  /// Ovos disponíveis (recolhidos - consumidos - vendidos)
  int get available => collected - consumed - sold;

  @override
  String toString() {
    return 'WeekStats(collected: $collected, consumed: $consumed, sold: $sold, '
        'revenue: €${revenue.toStringAsFixed(2)}, expenses: €${expenses.toStringAsFixed(2)}, '
        'netProfit: €${netProfit.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeekStats &&
        other.collected == collected &&
        other.consumed == consumed &&
        other.sold == sold &&
        other.revenue == revenue &&
        other.expenses == expenses &&
        other.netProfit == netProfit;
  }

  @override
  int get hashCode {
    return Object.hash(collected, consumed, sold, revenue, expenses, netProfit);
  }
}
