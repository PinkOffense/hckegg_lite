import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/date_utils.dart';
import '../core/utils/error_handler.dart';
import '../state/providers/providers.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/search_bar.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/scroll_to_top.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/egg_sale.dart';
import '../dialogs/sale_dialog.dart';
import '../services/csv_export_service.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return AppScaffold(
      title: t('egg_sales'),
      additionalActions: [
        IconButton(
          tooltip: t('export_csv'),
          icon: const Icon(Icons.download),
          onPressed: () {
            final sales = context.read<SaleProvider>().sales;
            if (sales.isEmpty) return;
            CsvExportService.exportSales(
              sales: sales,
              context: context,
              locale: locale,
            );
          },
        ),
      ],
      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, _) {
          final allSales = saleProvider.sales;
          final sales = _searchQuery.isEmpty
              ? allSales
              : saleProvider.search(_searchQuery);

          // Only show loading skeleton if there's no cached data
          if (saleProvider.isLoading && allSales.isEmpty) {
            return const SkeletonListView(itemCount: 4, itemHeight: 120);
          }

          // Show error only if there's no cached data
          if (saleProvider.error != null && allSales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    t('error_loading_sales'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(saleProvider.error ?? ''),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => saleProvider.loadSales(),
                    icon: const Icon(Icons.refresh),
                    label: Text(t('try_again')),
                  ),
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

          return Stack(
            children: [
            SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar (only show if there are sales)
                if (allSales.isNotEmpty)
                  AppSearchBar(
                    controller: _searchController,
                    hintText: t('search_sales'),
                    hasContent: _searchQuery.isNotEmpty,
                    onChanged: _onSearchChanged,
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
                                    t('sales_statistics'),
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
                                    label: t('total_sales'),
                                    value: totalSales.toString(),
                                    color: Colors.blue,
                                    icon: Icons.receipt_long,
                                  ),
                                  _SalesStat(
                                    label: t('eggs_sold'),
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
                                    label: t('total_revenue'),
                                    value: '€${totalRevenue.toStringAsFixed(2)}',
                                    color: Colors.green,
                                    icon: Icons.euro,
                                  ),
                                  _SalesStat(
                                    label: t('average_price'),
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
                            t('sales_history'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              '${sales.length} ${t('results')}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Sales List
                      if (allSales.isEmpty)
                        ChickenEmptyState(
                          title: t('no_sales'),
                          message: t('no_sales_message'),
                          actionLabel: t('add_sale'),
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
          ScrollToTopButton(scrollController: _scrollController),
          ],
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

  Future<void> _deleteSale(BuildContext context, EggSale sale) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: t('delete_record'),
      message: t('delete_record_confirm'),
      itemName: '${sale.quantitySold} ${t('eggs')} - €${sale.totalAmount.toStringAsFixed(2)}',
      locale: locale,
    );

    if (confirmed && context.mounted) {
      try {
        await context.read<SaleProvider>().deleteSale(sale.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('record_deleted')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ErrorHandler.logError('SalesPage._deleteSale', e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.getUserFriendlyMessage(e, locale)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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

    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(icon, size: 32, color: color, semanticLabel: label),
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
      ),
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
    final t = (String k) => Translations.of(locale, k);
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
                    tooltip: t('delete_sale'),
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
                    label: t('quantity'),
                    value: '${sale.quantitySold}',
                  ),
                  _InfoChip(
                    icon: Icons.euro,
                    label: t('price_per_egg'),
                    value: '€${sale.pricePerEgg.toStringAsFixed(2)}',
                  ),
                  _InfoChip(
                    icon: Icons.payments,
                    label: t('total'),
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
                      Translations.of(locale, 'dozen_eggs', params: {'dozens': '${sale.dozens}', 'individual': '${sale.individualEggs}'}),
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

    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(icon, size: 20, color: color, semanticLabel: label),
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
      ),
    );
  }
}
