import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_stock.dart';
import '../state/app_state.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../widgets/app_scaffold.dart';

class FeedStockPage extends StatefulWidget {
  const FeedStockPage({super.key});

  @override
  State<FeedStockPage> createState() => _FeedStockPageState();
}

class _FeedStockPageState extends State<FeedStockPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final appState = Provider.of<AppState>(context);

    final stocks = appState.getFeedStocks();
    final lowStockCount = appState.lowStockCount;
    final totalStock = appState.totalFeedStock;

    return AppScaffold(
      title: locale == 'pt' ? 'Stock de Ração' : 'Feed Stock',
      fab: FloatingActionButton.extended(
        onPressed: () => _addStock(context, locale),
        icon: const Icon(Icons.add),
        label: Text(locale == 'pt' ? 'Adicionar' : 'Add'),
      ),
      body: Column(
        children: [
          // Overview Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale == 'pt' ? 'Resumo do Stock' : 'Stock Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      icon: Icons.inventory_2,
                      label: locale == 'pt' ? 'Total em Stock' : 'Total Stock',
                      value: '${totalStock.toStringAsFixed(1)} kg',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.warning_amber,
                      label: locale == 'pt' ? 'Stock Baixo' : 'Low Stock',
                      value: lowStockCount.toString(),
                      color: lowStockCount > 0 ? Colors.red : Colors.green,
                    ),
                    _StatCard(
                      icon: Icons.category,
                      label: locale == 'pt' ? 'Tipos' : 'Types',
                      value: stocks.length.toString(),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stock List
          Expanded(
            child: stocks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          locale == 'pt'
                              ? 'Nenhum stock registado'
                              : 'No stock registered',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locale == 'pt'
                              ? 'Toque em + para adicionar ração'
                              : 'Tap + to add feed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: stocks.length,
                    itemBuilder: (context, index) {
                      final stock = stocks[index];
                      return _FeedStockCard(
                        stock: stock,
                        locale: locale,
                        onTap: () => _editStock(context, locale, stock),
                        onAddMovement: () => _addMovement(context, locale, stock),
                        onDelete: () => _deleteStock(context, locale, stock),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addStock(BuildContext context, String locale) {
    showDialog(
      context: context,
      builder: (context) => _FeedStockDialog(locale: locale),
    );
  }

  void _editStock(BuildContext context, String locale, FeedStock stock) {
    showDialog(
      context: context,
      builder: (context) => _FeedStockDialog(locale: locale, existingStock: stock),
    );
  }

  void _addMovement(BuildContext context, String locale, FeedStock stock) {
    showDialog(
      context: context,
      builder: (context) => _MovementDialog(locale: locale, stock: stock),
    );
  }

  void _deleteStock(BuildContext context, String locale, FeedStock stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Eliminar Stock' : 'Delete Stock'),
        content: Text(
          locale == 'pt'
              ? 'Tem certeza que deseja eliminar este stock?'
              : 'Are you sure you want to delete this stock?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).deleteFeedStock(stock.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(locale == 'pt' ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedStockCard extends StatelessWidget {
  final FeedStock stock;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onAddMovement;
  final VoidCallback onDelete;

  const _FeedStockCard({
    required this.stock,
    required this.locale,
    required this.onTap,
    required this.onAddMovement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color stockColor;
    if (stock.isLowStock) {
      stockColor = Colors.red;
    } else if (stock.currentQuantityKg < stock.minimumQuantityKg * 2) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }

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
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      stock.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
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
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Stock indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stock.currentQuantityKg.toStringAsFixed(1)} kg',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                      if (stock.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            locale == 'pt' ? 'BAIXO' : 'LOW',
                            style: const TextStyle(
                              color: Colors.red,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale == 'pt' ? 'Nível de stock' : 'Stock level',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${locale == 'pt' ? 'Mín' : 'Min'}: ${stock.minimumQuantityKg.toStringAsFixed(0)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (stock.currentQuantityKg / (stock.minimumQuantityKg * 3)).clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: stockColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onAddMovement,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(locale == 'pt' ? 'Movimento' : 'Movement'),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: locale == 'pt' ? 'Eliminar' : 'Delete',
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

class _FeedStockDialog extends StatefulWidget {
  final String locale;
  final FeedStock? existingStock;

  const _FeedStockDialog({
    required this.locale,
    this.existingStock,
  });

  @override
  State<_FeedStockDialog> createState() => _FeedStockDialogState();
}

class _FeedStockDialogState extends State<_FeedStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late FeedType _type;
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingStock != null) {
      _type = widget.existingStock!.type;
      _brandController.text = widget.existingStock!.brand ?? '';
      _quantityController.text = widget.existingStock!.currentQuantityKg.toString();
      _minQuantityController.text = widget.existingStock!.minimumQuantityKg.toString();
      _priceController.text = widget.existingStock!.pricePerKg?.toString() ?? '';
      _notesController.text = widget.existingStock!.notes ?? '';
    } else {
      _type = FeedType.layer;
      _minQuantityController.text = '10';
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStock != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? (widget.locale == 'pt' ? 'Editar Stock' : 'Edit Stock')
            : (widget.locale == 'pt' ? 'Novo Stock' : 'New Stock'),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type dropdown
              DropdownButtonFormField<FeedType>(
                value: _type,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Tipo de Ração' : 'Feed Type',
                  border: const OutlineInputBorder(),
                ),
                items: FeedType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Text(type.icon),
                        const SizedBox(width: 8),
                        Text(type.displayName(widget.locale)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Marca (opcional)' : 'Brand (optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Quantidade (kg)' : 'Quantity (kg)',
                  border: const OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return widget.locale == 'pt' ? 'Obrigatório' : 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return widget.locale == 'pt' ? 'Número inválido' : 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Min quantity
              TextFormField(
                controller: _minQuantityController,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Quantidade Mínima (kg)' : 'Minimum Quantity (kg)',
                  border: const OutlineInputBorder(),
                  suffixText: 'kg',
                  helperText: widget.locale == 'pt'
                      ? 'Alerta quando abaixo deste valor'
                      : 'Alert when below this value',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Price per kg
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Preço por kg (opcional)' : 'Price per kg (optional)',
                  border: const OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Notas (opcional)' : 'Notes (optional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.locale == 'pt' ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.locale == 'pt' ? 'Guardar' : 'Save'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final stock = FeedStock(
      id: widget.existingStock?.id ?? const Uuid().v4(),
      type: _type,
      brand: _brandController.text.isEmpty ? null : _brandController.text,
      currentQuantityKg: double.parse(_quantityController.text),
      minimumQuantityKg: double.tryParse(_minQuantityController.text) ?? 10.0,
      pricePerKg: double.tryParse(_priceController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      lastUpdated: now,
      createdAt: widget.existingStock?.createdAt ?? now,
    );

    Provider.of<AppState>(context, listen: false).saveFeedStock(stock);
    Navigator.pop(context);
  }
}

class _MovementDialog extends StatefulWidget {
  final String locale;
  final FeedStock stock;

  const _MovementDialog({
    required this.locale,
    required this.stock,
  });

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  StockMovementType _movementType = StockMovementType.purchase;
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.locale == 'pt' ? 'Registar Movimento' : 'Record Movement',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Movement type
            DropdownButtonFormField<StockMovementType>(
              value: _movementType,
              decoration: InputDecoration(
                labelText: widget.locale == 'pt' ? 'Tipo de Movimento' : 'Movement Type',
                border: const OutlineInputBorder(),
              ),
              items: StockMovementType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName(widget.locale)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _movementType = value);
              },
            ),
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: widget.locale == 'pt' ? 'Quantidade (kg)' : 'Quantity (kg)',
                border: const OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Cost (for purchases)
            if (_movementType == StockMovementType.purchase) ...[
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: widget.locale == 'pt' ? 'Custo (opcional)' : 'Cost (optional)',
                  border: const OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: widget.locale == 'pt' ? 'Notas (opcional)' : 'Notes (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.locale == 'pt' ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.locale == 'pt' ? 'Guardar' : 'Save'),
        ),
      ],
    );
  }

  void _save() {
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) return;

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final movement = FeedMovement(
      id: const Uuid().v4(),
      feedStockId: widget.stock.id,
      movementType: _movementType,
      quantityKg: quantity,
      cost: double.tryParse(_costController.text),
      date: dateStr,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: now,
    );

    Provider.of<AppState>(context, listen: false).addFeedMovement(movement, widget.stock);
    Navigator.pop(context);
  }
}
