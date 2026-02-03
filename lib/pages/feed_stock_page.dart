import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/feed_stock.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import '../widgets/gradient_fab.dart';
import '../dialogs/feed_stock_dialog.dart';

class FeedStockPage extends StatefulWidget {
  const FeedStockPage({super.key});

  @override
  State<FeedStockPage> createState() => _FeedStockPageState();
}

class _FeedStockPageState extends State<FeedStockPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<FeedStockProvider>().loadFeedStocks();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return AppScaffold(
      title: t('feed_stock'),
      fab: GradientFAB(
        extended: true,
        icon: Icons.add,
        label: t('add_feed_stock'),
        onPressed: () => _showAddDialog(context),
      ),
      body: Consumer<FeedStockProvider>(
        builder: (context, provider, _) {
          return _buildContent(context, locale, provider);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, String locale, FeedStockProvider provider) {
    final theme = Theme.of(context);
    final t = (String k) => Translations.of(locale, k);

    // Loading state
    if (provider.isLoading && provider.feedStocks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (provider.hasError && provider.feedStocks.isEmpty) {
      return _ErrorView(
        locale: locale,
        errorMessage: provider.errorMessage,
        onRetry: _refresh,
      );
    }

    // Content
    final allStocks = provider.feedStocks;
    final stocks = _searchQuery.isEmpty
        ? allStocks
        : provider.search(_searchQuery);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Overview
          SliverToBoxAdapter(
            child: _OverviewCard(
              locale: locale,
              totalStock: provider.totalFeedStock,
              lowStockCount: provider.lowStockCount,
              stockCount: allStocks.length,
            ),
          ),

          // Search
          if (allStocks.isNotEmpty)
            SliverToBoxAdapter(
              child: AppSearchBar(
                controller: _searchController,
                hintText: t('search_feed'),
                hasContent: _searchQuery.isNotEmpty,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),

          // Empty state
          if (allStocks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.grass_outlined,
                title: t('no_stock'),
                message: t('add_feed_to_start'),
                actionLabel: t('add'),
                onAction: () => _showAddDialog(context),
              ),
            )
          else if (stocks.isEmpty)
            SliverFillRemaining(
              child: SearchEmptyState(
                query: _searchQuery,
                locale: locale,
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: stocks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stock = stocks[index];
                  return _StockCard(
                    key: ValueKey(stock.id),
                    stock: stock,
                    locale: locale,
                    onConsume: () => _showConsumeDialog(context, locale, stock),
                    onEdit: () => _showEditDialog(context, stock),
                    onDelete: () => _showDeleteDialog(context, locale, stock),
                  );
                },
              ),
            ),

          // FAB spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const FeedStockDialog(),
    );
  }

  void _showEditDialog(BuildContext context, FeedStock stock) {
    showDialog(
      context: context,
      builder: (_) => FeedStockDialog(existingStock: stock),
    );
  }

  void _showConsumeDialog(BuildContext context, String locale, FeedStock stock) {
    showDialog(
      context: context,
      builder: (_) => _ConsumeDialog(locale: locale, stock: stock),
    );
  }

  void _showDeleteDialog(BuildContext context, String locale, FeedStock stock) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(Translations.of(locale, 'delete_question')),
        content: Text(
          '${Translations.of(locale, 'delete')} "${stock.type.displayName(locale)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.of(locale, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<FeedStockProvider>().deleteFeedStock(stock.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(Translations.of(locale, 'delete')),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ERROR VIEW
// =============================================================================

class _ErrorView extends StatelessWidget {
  final String locale;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.locale,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              Translations.of(locale, 'error_loading'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.of(locale, 'check_tables_msg'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(Translations.of(locale, 'retry')),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// OVERVIEW CARD
// =============================================================================

class _OverviewCard extends StatelessWidget {
  final String locale;
  final double totalStock;
  final int lowStockCount;
  final int stockCount;

  const _OverviewCard({
    required this.locale,
    required this.totalStock,
    required this.lowStockCount,
    required this.stockCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translations.of(locale, 'overview'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.inventory_2,
                  label: Translations.of(locale, 'total'),
                  value: '${totalStock.toStringAsFixed(1)} kg',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  icon: Icons.warning_amber,
                  label: Translations.of(locale, 'low'),
                  value: lowStockCount.toString(),
                  color: lowStockCount > 0 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  icon: Icons.category,
                  label: Translations.of(locale, 'types'),
                  value: stockCount.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STOCK CARD
// =============================================================================

class _StockCard extends StatelessWidget {
  final FeedStock stock;
  final String locale;
  final VoidCallback onConsume;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StockCard({
    super.key,
    required this.stock,
    required this.locale,
    required this.onConsume,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _levelColor {
    if (stock.isLowStock) return Colors.red;
    if (stock.currentQuantityKg < stock.minimumQuantityKg * 2) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(stock.type.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.type.displayName(locale),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stock.brand != null)
                          Text(
                            stock.brand!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stock.currentQuantityKg.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _levelColor,
                        ),
                      ),
                      if (stock.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            Translations.of(locale, 'low_stock'),
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (stock.currentQuantityKg / (stock.minimumQuantityKg * 3)).clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: _levelColor,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${Translations.of(locale, 'min_stock')}: ${stock.minimumQuantityKg.toStringAsFixed(0)} kg',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: stock.currentQuantityKg > 0 ? onConsume : null,
                      icon: const Icon(Icons.restaurant, size: 18),
                      label: Text(Translations.of(locale, 'consume')),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: Translations.of(locale, 'delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CONSUME DIALOG
// =============================================================================

class _ConsumeDialog extends StatefulWidget {
  final String locale;
  final FeedStock stock;

  const _ConsumeDialog({required this.locale, required this.stock});

  @override
  State<_ConsumeDialog> createState() => _ConsumeDialogState();
}

class _ConsumeDialogState extends State<_ConsumeDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _quantity => double.tryParse(_controller.text) ?? 0;
  double get _newStock => widget.stock.currentQuantityKg - _quantity;
  bool get _isValid => _quantity > 0 && _newStock >= 0;

  Future<void> _save() async {
    if (!_isValid) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final movement = FeedMovement(
        id: const Uuid().v4(),
        feedStockId: widget.stock.id,
        movementType: StockMovementType.consumption,
        quantityKg: _quantity,
        date: dateStr,
        createdAt: now,
      );

      final provider = context.read<FeedStockProvider>();
      final success = await provider.addFeedMovement(movement, widget.stock);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.of(widget.locale, 'consumption_recorded'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _saving = false;
          _error = provider.errorMessage ?? 'Error';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.restaurant, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Translations.of(widget.locale, 'record_consumption'),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock info
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(widget.stock.type.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.stock.type.displayName(widget.locale),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${Translations.of(widget.locale, 'current')}: ${widget.stock.currentQuantityKg.toStringAsFixed(1)} kg',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Quantity input
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: Translations.of(widget.locale, 'quantity_kg'),
                border: const OutlineInputBorder(),
                suffixText: 'kg',
                errorText: _error,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => setState(() => _error = null),
            ),

            // Preview
            if (_quantity > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _newStock < 0 ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Translations.of(widget.locale, 'after_consumption')),
                    Text(
                      '${_newStock.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _newStock < 0 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_newStock < 0 && _quantity > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${Translations.of(widget.locale, 'max_label')}: ${widget.stock.currentQuantityKg.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(Translations.of(widget.locale, 'cancel')),
        ),
        FilledButton(
          onPressed: (_isValid && !_saving) ? _save : null,
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(Translations.of(widget.locale, 'confirm')),
        ),
      ],
    );
  }
}
