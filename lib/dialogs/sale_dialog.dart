import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/egg_sale.dart';
import '../state/app_state.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class SaleDialog extends StatefulWidget {
  final EggSale? existingSale;

  const SaleDialog({super.key, this.existingSale});

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _pricePerEggController = TextEditingController();
  final _pricePerDozenController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    if (widget.existingSale != null) {
      // Editing existing sale
      _selectedDate = DateTime.parse(widget.existingSale!.date);
      _quantityController.text = widget.existingSale!.quantitySold.toString();
      _pricePerEggController.text = widget.existingSale!.pricePerEgg.toStringAsFixed(2);
      _pricePerDozenController.text = widget.existingSale!.pricePerDozen.toStringAsFixed(2);
      _customerNameController.text = widget.existingSale!.customerName ?? '';
      _customerEmailController.text = widget.existingSale!.customerEmail ?? '';
      _customerPhoneController.text = widget.existingSale!.customerPhone ?? '';
      _notesController.text = widget.existingSale!.notes ?? '';
    } else {
      // New sale
      _selectedDate = DateTime.now();
      // Set default prices (can be changed by user)
      _pricePerEggController.text = '0.50';
      _pricePerDozenController.text = '5.50';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pricePerEggController.dispose();
    _pricePerDozenController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.existingSale != null
                        ? (locale == 'pt' ? 'Editar Venda' : 'Edit Sale')
                        : (locale == 'pt' ? 'Nova Venda' : 'New Sale'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date
                  InkWell(
                    onTap: () => _selectDate(context, locale),
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: t('date'),
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        _formatDate(_selectedDate, locale),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: '${locale == 'pt' ? 'Quantidade de Ovos' : 'Quantity of Eggs'} *',
                      prefixIcon: const Icon(Icons.egg),
                      suffixText: locale == 'pt' ? 'ovos' : 'eggs',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                      }
                      if (int.tryParse(value) == null) {
                        return locale == 'pt' ? 'Valor inválido' : 'Invalid value';
                      }
                      if (int.parse(value) <= 0) {
                        return locale == 'pt' ? 'Deve ser maior que zero' : 'Must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price per egg and dozen
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pricePerEggController,
                          decoration: InputDecoration(
                            labelText: '${locale == 'pt' ? 'Preço/Ovo' : 'Price/Egg'} *',
                            prefixIcon: const Icon(Icons.euro),
                            suffixText: '€',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return locale == 'pt' ? 'Obrigatório' : 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return locale == 'pt' ? 'Inválido' : 'Invalid';
                            }
                            if (double.parse(value) <= 0) {
                              return locale == 'pt' ? '> 0' : '> 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _pricePerDozenController,
                          decoration: InputDecoration(
                            labelText: '${locale == 'pt' ? 'Preço/Dúzia' : 'Price/Dozen'} *',
                            prefixIcon: const Icon(Icons.attach_money),
                            suffixText: '€',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return locale == 'pt' ? 'Obrigatório' : 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return locale == 'pt' ? 'Inválido' : 'Invalid';
                            }
                            if (double.parse(value) <= 0) {
                              return locale == 'pt' ? '> 0' : '> 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Customer Information Section
                  Row(
                    children: [
                      Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'pt' ? 'Informação do Cliente (opcional)' : 'Customer Information (optional)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer Name
                  TextFormField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: locale == 'pt' ? 'Nome do Cliente' : 'Customer Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Email
                  TextFormField(
                    controller: _customerEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Customer Phone
                  TextFormField(
                    controller: _customerPhoneController,
                    decoration: InputDecoration(
                      labelText: locale == 'pt' ? 'Telefone' : 'Phone',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Notes (optional)
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: '${t('notes')} (${t('optional')})',
                      prefixIcon: const Icon(Icons.note),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _saveSale,
                        icon: const Icon(Icons.check),
                        label: Text(t('save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, String locale) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: Locale(locale),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date, String locale) {
    if (locale == 'pt') {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _saveSale() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final pricePerEgg = double.parse(_pricePerEggController.text);
    final pricePerDozen = double.parse(_pricePerDozenController.text);
    final customerName = _customerNameController.text.trim();
    final customerEmail = _customerEmailController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    final notes = _notesController.text.trim();

    final sale = EggSale(
      id: widget.existingSale?.id ?? const Uuid().v4(),
      date: _dateToString(_selectedDate),
      quantitySold: quantity,
      pricePerEgg: pricePerEgg,
      pricePerDozen: pricePerDozen,
      customerName: customerName.isEmpty ? null : customerName,
      customerEmail: customerEmail.isEmpty ? null : customerEmail,
      customerPhone: customerPhone.isEmpty ? null : customerPhone,
      notes: notes.isEmpty ? null : notes,
      createdAt: widget.existingSale?.createdAt ?? DateTime.now(),
    );

    Provider.of<AppState>(context, listen: false).saveSale(sale);

    Navigator.pop(context);
  }
}
