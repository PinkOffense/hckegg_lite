import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_stock.dart';
import '../state/app_state.dart';
import '../l10n/locale_provider.dart';

class FeedStockDialog extends StatefulWidget {
  final FeedStock? existingStock;

  const FeedStockDialog({super.key, this.existingStock});

  @override
  State<FeedStockDialog> createState() => _FeedStockDialogState();
}

class _FeedStockDialogState extends State<FeedStockDialog> {
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
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final isEditing = widget.existingStock != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing
                          ? (locale == 'pt' ? 'Editar Stock' : 'Edit Stock')
                          : (locale == 'pt' ? 'Novo Stock de Ração' : 'New Feed Stock'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Type dropdown
                    DropdownButtonFormField<FeedType>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Tipo de Ração' : 'Feed Type',
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: FeedType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Text(type.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(type.displayName(locale)),
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
                        labelText: locale == 'pt' ? 'Marca (opcional)' : 'Brand (optional)',
                        prefixIcon: const Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: '${locale == 'pt' ? 'Quantidade' : 'Quantity'} (kg) *',
                        prefixIcon: const Icon(Icons.scale),
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                        }
                        if (double.tryParse(value) == null) {
                          return locale == 'pt' ? 'Número inválido' : 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Min quantity
                    TextFormField(
                      controller: _minQuantityController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Quantidade Mínima (kg)' : 'Minimum Quantity (kg)',
                        prefixIcon: const Icon(Icons.warning_amber),
                        suffixText: 'kg',
                        helperText: locale == 'pt'
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
                        labelText: locale == 'pt' ? 'Preço por kg (opcional)' : 'Price per kg (optional)',
                        prefixIcon: const Icon(Icons.euro),
                        prefixText: '€ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Notas (opcional)' : 'Notes (optional)',
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(locale == 'pt' ? 'Guardar' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
