import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/egg_sale.dart';
import '../dialogs/sale_dialog.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return AppScaffold(
      title: locale == 'pt' ? 'Gestão de Pagamentos' : 'Payment Management',
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final sales = state.sales;

          // Categorize sales
          final paidSales = sales.where((s) => s.paymentStatus == PaymentStatus.paid).toList();
          final pendingSales = sales.where((s) => s.paymentStatus == PaymentStatus.pending).toList();
          final overdueSales = sales.where((s) => s.paymentStatus == PaymentStatus.overdue).toList();
          final advanceSales = sales.where((s) => s.paymentStatus == PaymentStatus.advance).toList();
          final reservations = sales.where((s) => s.isReservation).toList();

          // Calculate totals
          final totalPaid = paidSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final totalPending = pendingSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final totalOverdue = overdueSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final totalAdvance = advanceSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _PaymentSummaryCards(
                  totalPaid: totalPaid,
                  totalPending: totalPending,
                  totalOverdue: totalOverdue,
                  totalAdvance: totalAdvance,
                  locale: locale,
                ),
                const SizedBox(height: 24),

                // Overdue Payments
                if (overdueSales.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.error_outline,
                    title: locale == 'pt' ? 'Pagamentos Atrasados' : 'Overdue Payments',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  ...overdueSales.map((sale) => _PaymentCard(
                        sale: sale,
                        locale: locale,
                        onTap: () => _showSaleDialog(context, sale),
                        onMarkPaid: () => _markAsPaid(context, sale),
                      )),
                  const SizedBox(height: 24),
                ],

                // Pending Payments
                if (pendingSales.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.hourglass_empty,
                    title: locale == 'pt' ? 'Pagamentos Pendentes' : 'Pending Payments',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  ...pendingSales.map((sale) => _PaymentCard(
                        sale: sale,
                        locale: locale,
                        onTap: () => _showSaleDialog(context, sale),
                        onMarkPaid: () => _markAsPaid(context, sale),
                      )),
                  const SizedBox(height: 24),
                ],

                // Advance Payments
                if (advanceSales.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.account_balance_wallet,
                    title: locale == 'pt' ? 'Pagamentos Adiantados' : 'Advance Payments',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  ...advanceSales.map((sale) => _PaymentCard(
                        sale: sale,
                        locale: locale,
                        onTap: () => _showSaleDialog(context, sale),
                      )),
                  const SizedBox(height: 24),
                ],

                // Reservations
                if (reservations.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.bookmark,
                    title: locale == 'pt' ? 'Reservas de Ovos' : 'Egg Reservations',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  ...reservations.map((sale) => _ReservationCard(
                        sale: sale,
                        locale: locale,
                        onTap: () => _showSaleDialog(context, sale),
                        onMarkPaid: sale.paymentStatus != PaymentStatus.paid
                            ? () => _markAsPaid(context, sale)
                            : null,
                      )),
                  const SizedBox(height: 24),
                ],

                // Paid Sales (Last 10)
                _SectionHeader(
                  icon: Icons.check_circle,
                  title: locale == 'pt' ? 'Pagamentos Recentes (Pagos)' : 'Recent Payments (Paid)',
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                if (paidSales.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          locale == 'pt' ? 'Nenhum pagamento registado' : 'No payments registered',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...paidSales.take(10).map((sale) => _PaymentCard(
                        sale: sale,
                        locale: locale,
                        onTap: () => _showSaleDialog(context, sale),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSaleDialog(BuildContext context, EggSale sale) {
    showDialog(
      context: context,
      builder: (_) => SaleDialog(existingSale: sale),
    );
  }

  Future<void> _markAsPaid(BuildContext context, EggSale sale) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final updatedSale = sale.copyWith(
      paymentStatus: PaymentStatus.paid,
      paymentDate: dateStr,
    );

    try {
      await appState.saveSale(updatedSale);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento marcado como pago'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PaymentSummaryCards extends StatelessWidget {
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final double totalAdvance;
  final String locale;

  const _PaymentSummaryCards({
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.totalAdvance,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: locale == 'pt' ? 'Total Pago' : 'Total Paid',
                amount: totalPaid,
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: locale == 'pt' ? 'Pendente' : 'Pending',
                amount: totalPending,
                color: Colors.orange,
                icon: Icons.hourglass_empty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: locale == 'pt' ? 'Atrasado' : 'Overdue',
                amount: totalOverdue,
                color: Colors.red,
                icon: Icons.error_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: locale == 'pt' ? 'Adiantado' : 'Advance',
                amount: totalAdvance,
                color: Colors.blue,
                icon: Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '€${amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final EggSale sale;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onMarkPaid;

  const _PaymentCard({
    required this.sale,
    required this.locale,
    required this.onTap,
    this.onMarkPaid,
  });

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    if (locale == 'pt') {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Color _getStatusColor() {
    switch (sale.paymentStatus) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.advance:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName ?? (locale == 'pt' ? 'Cliente sem nome' : 'Unnamed customer'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(sale.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(), width: 1.5),
                    ),
                    child: Text(
                      sale.paymentStatus.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sale.quantitySold} ${locale == 'pt' ? 'ovos' : 'eggs'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '€${sale.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (sale.paymentDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${locale == 'pt' ? 'Pago em' : 'Paid on'}: ${_formatDate(sale.paymentDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
              if (onMarkPaid != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(locale == 'pt' ? 'Marcar como Pago' : 'Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final EggSale sale;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onMarkPaid;

  const _ReservationCard({
    required this.sale,
    required this.locale,
    required this.onTap,
    this.onMarkPaid,
  });

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    if (locale == 'pt') {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = sale.paymentStatus == PaymentStatus.paid || sale.paymentStatus == PaymentStatus.advance;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName ?? (locale == 'pt' ? 'Cliente sem nome' : 'Unnamed customer'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${locale == 'pt' ? 'Reserva para' : 'Reserved for'}: ${_formatDate(sale.date)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPaid ? Colors.green : Colors.orange,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isPaid ? (locale == 'pt' ? 'Pago' : 'Paid') : (locale == 'pt' ? 'Não pago' : 'Unpaid'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPaid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sale.quantitySold} ${locale == 'pt' ? 'ovos reservados' : 'eggs reserved'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '€${sale.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (sale.reservationNotes != null && sale.reservationNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sale.reservationNotes!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onMarkPaid != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(locale == 'pt' ? 'Marcar como Pago' : 'Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
