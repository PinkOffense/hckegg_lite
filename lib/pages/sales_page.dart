import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/date_utils.dart';
import '../state/providers/providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/search_bar.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/egg_sale.dart';
import '../dialogs/sale_dialog.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return AppScaffold(
      title: locale == 'pt' ? 'Vendas de Ovos' : 'Egg Sales',
      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, _) {
          final allSales = saleProvider.sales;
          final sales = _searchQuery.isEmpty
              ? allSales
              : saleProvider.search(_searchQuery);

          if (saleProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (saleProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    locale == 'pt' ? 'Erro ao carregar vendas' : 'Error loading sales',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(saleProvider.error!),
                ],
              ),
            );
          }

          // Calculate statistics (always from all sales, not filtered)
          final totalSales = allSales.length;
          final totalQuantity = allSales.fold<int>(0, (sum, s) => sum + s.quantitySold);
          final totalRevenue = allSales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
          final avgPrice = allSales.isEmpty
              ? 0.0
              : allSales.fold<double>(0.0, (sum, s) => sum + s.pricePerEgg) / allSales.length;

          return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar (only show if there are sales)
                    if (allSales.isNotEmpty)
                      AppSearchBar(
                        controller: _searchController,
                        hintText: locale == 'pt'
                            ? 'Pesquisar por cliente, notas...'
                            : 'Search by customer, notes...',
                        hasContent: _searchQuery.isNotEmpty,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // Statistics Card
                    Card(
                      elevation: 4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sell,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  locale == 'pt' ? 'Estatísticas de Vendas' : 'Sales Statistics',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _SalesStat(
                                  label: locale == 'pt' ? 'Total Vendas' : 'Total Sales',
                                  value: totalSales.toString(),
                                  color: Colors.blue,
                                  icon: Icons.receipt_long,
                                ),
                                _SalesStat(
                                  label: locale == 'pt' ? 'Ovos Vendidos' : 'Eggs Sold',
                                  value: totalQuantity.toString(),
                                  color: Colors.orange,
                                  icon: Icons.egg,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _SalesStat(
                                  label: locale == 'pt' ? 'Receita Total' : 'Total Revenue',
                                  value: '€${totalRevenue.toStringAsFixed(2)}',
                                  color: Colors.green,
                                  icon: Icons.euro,
                                ),
                                _SalesStat(
                                  label: locale == 'pt' ? 'Preço Médio' : 'Average Price',
                                  value: '€${avgPrice.toStringAsFixed(2)}',
                                  color: Colors.purple,
                                  icon: Icons.trending_up,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sales List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale == 'pt' ? 'Histórico de Vendas' : 'Sales History',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            '${sales.length} ${locale == 'pt' ? 'resultado(s)' : 'result(s)'}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Sales List
                    if (allSales.isEmpty)
                      ChickenEmptyState(
                        title: locale == 'pt' ? 'Nenhuma venda registada' : 'No sales recorded',
                        message: locale == 'pt'
                            ? 'Registe as vendas de ovos e acompanhe as suas receitas'
                            : 'Record egg sales and track your revenue',
                        actionLabel: locale == 'pt' ? 'Adicionar Venda' : 'Add Sale',
                        onAction: () => _showSaleDialog(context, null),
                      )
                    else if (sales.isEmpty && _searchQuery.isNotEmpty)
                      SearchEmptyState(
                        query: _searchQuery,
                        locale: locale,
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    else
                      ...sales.map((sale) => _SaleCard(
                            sale: sale,
                            locale: locale,
                            onTap: () => _showSaleDialog(context, sale),
                            onDelete: () => _deleteSale(context, sale),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          );
        },
      ),
      fab: GradientFAB(
        extended: true,
        icon: Icons.add,
        label: t('add_sale'),
        onPressed: () => _showSaleDialog(context, null),
      ),
    );
  }

  void _showSaleDialog(BuildContext context, EggSale? existingSale) {
    showDialog(
      context: context,
      builder: (context) => SaleDialog(existingSale: existingSale),
    );
  }

  void _deleteSale(BuildContext context, EggSale sale) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Eliminar Venda' : 'Delete Sale'),
        content: Text(
          locale == 'pt'
              ? 'Tem a certeza que deseja eliminar esta venda?'
              : 'Are you sure you want to delete this sale?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(locale == 'pt' ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<SaleProvider>().deleteSale(sale.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale == 'pt'
                    ? 'Venda eliminada com sucesso'
                    : 'Sale deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale == 'pt' ? 'Erro ao eliminar' : 'Error deleting'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _SalesStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SalesStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SaleCard extends StatelessWidget {
  final EggSale sale;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SaleCard({
    required this.sale,
    required this.locale,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = AppDateUtils.formatFullFromString(sale.date, locale: locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sell, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (sale.customerName != null)
                            Text(
                              sale.customerName!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: onDelete,
                    tooltip: locale == 'pt' ? 'Eliminar venda' : 'Delete sale',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    icon: Icons.egg,
                    label: locale == 'pt' ? 'Quantidade' : 'Quantity',
                    value: '${sale.quantitySold}',
                  ),
                  _InfoChip(
                    icon: Icons.euro,
                    label: locale == 'pt' ? 'Preço/Ovo' : 'Price/Egg',
                    value: '€${sale.pricePerEgg.toStringAsFixed(2)}',
                  ),
                  _InfoChip(
                    icon: Icons.payments,
                    label: locale == 'pt' ? 'Total' : 'Total',
                    value: '€${sale.totalAmount.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                ],
              ),
              if (sale.dozens > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      locale == 'pt'
                          ? '${sale.dozens} dúzia(s) + ${sale.individualEggs} ovos'
                          : '${sale.dozens} dozen + ${sale.individualEggs} eggs',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sale.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight ? Colors.green : theme.textTheme.bodyMedium?.color;

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
