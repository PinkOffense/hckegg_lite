import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/providers/providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/egg_sale.dart';
import '../dialogs/sale_dialog.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EggSale> _filterSales(List<EggSale> sales) {
    if (_searchQuery.isEmpty) return sales;
    final q = _searchQuery.toLowerCase();
    return sales.where((sale) {
      final customerMatch = sale.customerName?.toLowerCase().contains(q) ?? false;
      final notesMatch = sale.notes?.toLowerCase().contains(q) ?? false;
      final amountMatch = sale.totalAmount.toStringAsFixed(2).contains(q);
      return customerMatch || notesMatch || amountMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return AppScaffold(
      title: locale == 'pt' ? 'Gestão de Pagamentos' : 'Payment Management',
      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, _) {
          final allSales = saleProvider.sales;

          // Categorize all sales (for totals)
          final allPaidSales = allSales.where((s) => !s.isLost && s.paymentStatus == PaymentStatus.paid).toList();
          final allPendingSales = allSales.where((s) => !s.isLost && s.paymentStatus == PaymentStatus.pending).toList();
          final allAdvanceSales = allSales.where((s) => !s.isLost && s.paymentStatus == PaymentStatus.advance).toList();
          final allLostSales = allSales.where((s) => s.isLost).toList();

          // Calculate totals (always show full totals)
          final totalPaid = allPaidSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final totalPending = allPendingSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final totalLost = allLostSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final totalAdvance = allAdvanceSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);

          // Filter sales for display
          final paidSales = _filterSales(allPaidSales);
          final pendingSales = _filterSales(allPendingSales);
          final advanceSales = _filterSales(allAdvanceSales);
          final lostSales = _filterSales(allLostSales);

          final hasAnyResults = paidSales.isNotEmpty || pendingSales.isNotEmpty || advanceSales.isNotEmpty || lostSales.isNotEmpty;

          return Column(
            children: [
              // Search Bar (only show if there are sales)
              if (allSales.isNotEmpty)
                AppSearchBar(
                  controller: _searchController,
                  hintText: locale == 'pt' ? 'Pesquisar por cliente...' : 'Search by customer...',
                  hasContent: _searchQuery.isNotEmpty,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),

              // Content
              Expanded(
                child: _searchQuery.isNotEmpty && !hasAnyResults
                    ? SearchEmptyState(
                        query: _searchQuery,
                        locale: locale,
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Cards
                            _PaymentSummaryCards(
                              totalPaid: totalPaid,
                              totalPending: totalPending,
                              totalLost: totalLost,
                              totalAdvance: totalAdvance,
                              locale: locale,
                            ),
                            const SizedBox(height: 24),

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
                                    onMarkLost: () => _markAsLost(context, sale),
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

                            // Lost Sales (customer never paid)
                            if (lostSales.isNotEmpty) ...[
                              _SectionHeader(
                                icon: Icons.cancel,
                                title: locale == 'pt' ? 'Vendas Perdidas' : 'Lost Sales',
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(height: 12),
                              ...lostSales.map((sale) => _PaymentCard(
                                    sale: sale,
                                    locale: locale,
                                    onTap: () => _showSaleDialog(context, sale),
                                  )),
                              const SizedBox(height: 24),
                            ],

                            // Paid Sales (All - Permanent Record)
                            if (paidSales.isNotEmpty) ...[
                              _SectionHeader(
                                icon: Icons.check_circle,
                                title: locale == 'pt' ? 'Pagamentos Realizados' : 'Completed Payments',
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              ...paidSales.map((sale) => _PaymentCard(
                                    sale: sale,
                                    locale: locale,
                                    onTap: () => _showSaleDialog(context, sale),
                                  )),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
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
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final saleProvider = context.read<SaleProvider>();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(locale == 'pt' ? 'Atualizando...' : 'Updating...'),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final updatedSale = sale.copyWith(
      paymentStatus: PaymentStatus.paid,
      paymentDate: dateStr,
      isLost: false, // Ensure it's not marked as lost
    );

    try {
      await saleProvider.saveSale(updatedSale);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale == 'pt'
                  ? '✓ Pagamento marcado como pago'
                  : '✓ Payment marked as paid',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsLost(BuildContext context, EggSale sale) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Marcar como Perdida?' : 'Mark as Lost?'),
        content: Text(
          locale == 'pt'
              ? 'Esta venda será marcada como perdida (cliente nunca pagará). Esta ação não pode ser desfeita. Continuar?'
              : 'This sale will be marked as lost (customer will never pay). This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(locale == 'pt' ? 'Marcar como Perdida' : 'Mark as Lost'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final saleProvider = context.read<SaleProvider>();

    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(locale == 'pt' ? 'Atualizando...' : 'Updating...'),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final updatedSale = sale.copyWith(
      isLost: true,
      paymentStatus: PaymentStatus.overdue, // Keep status to show it was unpaid
    );

    try {
      await saleProvider.saveSale(updatedSale);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale == 'pt'
                  ? '✗ Venda marcada como perdida'
                  : '✗ Sale marked as lost',
            ),
            backgroundColor: Colors.grey.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
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
  final double totalLost;
  final double totalAdvance;
  final String locale;

  const _PaymentSummaryCards({
    required this.totalPaid,
    required this.totalPending,
    required this.totalLost,
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
                title: locale == 'pt' ? 'Perdido' : 'Lost',
                amount: totalLost,
                color: Colors.grey,
                icon: Icons.cancel_outlined,
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
  final VoidCallback? onMarkLost;

  const _PaymentCard({
    required this.sale,
    required this.locale,
    required this.onTap,
    this.onMarkPaid,
    this.onMarkLost,
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
                      color: _getStatusColor().withValues(alpha: 0.1),
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
              if (sale.isLost) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'pt' ? 'Venda perdida - cliente nunca pagou' : 'Lost sale - customer never paid',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onMarkPaid != null || onMarkLost != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onMarkPaid != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onMarkPaid,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(locale == 'pt' ? 'Pago' : 'Paid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (onMarkPaid != null && onMarkLost != null) const SizedBox(width: 12),
                    if (onMarkLost != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onMarkLost,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: Text(locale == 'pt' ? 'Perdida' : 'Lost'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
