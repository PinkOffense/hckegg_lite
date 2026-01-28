import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../models/egg_sale.dart';
import '../state/providers/providers.dart';
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
  late PaymentStatus _paymentStatus;
  DateTime? _paymentDate;
  bool _updatingPrices = false;
  final _totalPriceController = TextEditingController();

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
      _paymentStatus = widget.existingSale!.paymentStatus;
      _paymentDate = widget.existingSale!.paymentDate != null
          ? DateTime.parse(widget.existingSale!.paymentDate!)
          : null;
    } else {
      // New sale
      _selectedDate = DateTime.now();
      _paymentStatus = PaymentStatus.pending;
      // Set default prices (can be changed by user)
      _pricePerEggController.text = '0.50';
      _pricePerDozenController.text = '6.00'; // 0.50 * 12 = 6.00
    }

    // Add listeners to sync price fields and calculate total
    _pricePerEggController.addListener(_onPricePerEggChanged);
    _pricePerDozenController.addListener(_onPricePerDozenChanged);
    _quantityController.addListener(_calculateTotal);

    // Calculate initial total
    _calculateTotal();
  }

  void _onPricePerEggChanged() {
    if (_updatingPrices) return;

    final text = _pricePerEggController.text;
    final price = double.tryParse(text);

    if (price != null && price > 0) {
      _updatingPrices = true;
      final dozenPrice = price * 12;
      _pricePerDozenController.text = dozenPrice.toStringAsFixed(2);
      _updatingPrices = false;
      _calculateTotal();
    }
  }

  void _onPricePerDozenChanged() {
    if (_updatingPrices) return;

    final text = _pricePerDozenController.text;
    final price = double.tryParse(text);

    if (price != null && price > 0) {
      _updatingPrices = true;
      final eggPrice = price / 12;
      _pricePerEggController.text = eggPrice.toStringAsFixed(2);
      _updatingPrices = false;
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text);
    final pricePerEgg = double.tryParse(_pricePerEggController.text);
    final pricePerDozen = double.tryParse(_pricePerDozenController.text);

    if (quantity != null && quantity > 0 && pricePerEgg != null && pricePerEgg > 0 && pricePerDozen != null && pricePerDozen > 0) {
      // Calculate using dozen + individual eggs for better pricing
      final dozens = quantity ~/ 12;
      final individualEggs = quantity % 12;
      final total = (dozens * pricePerDozen) + (individualEggs * pricePerEgg);

      _totalPriceController.text = total.toStringAsFixed(2);
    } else {
      _totalPriceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pricePerEggController.dispose();
    _pricePerDozenController.dispose();
    _totalPriceController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 850),
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
                    Icons.point_of_sale,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingSale != null
                          ? (locale == 'pt' ? 'Editar Venda' : 'Edit Sale')
                          : (locale == 'pt' ? 'Nova Venda' : 'New Sale'),
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
                    // Date
                    InkWell(
                      onTap: () => _selectDate(context, locale),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: t('date'),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _formatDate(_selectedDate, locale),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: '${locale == 'pt' ? 'Quantidade de Ovos' : 'Quantity of Eggs'} *',
                        prefixIcon: const Icon(Icons.egg),
                        suffixText: locale == 'pt' ? 'ovos' : 'eggs',
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
                              prefixIcon: const Icon(Icons.euro),
                              suffixText: '€',
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
                    const SizedBox(height: 16),

                    // Total Price (calculated automatically)
                    TextFormField(
                      controller: _totalPriceController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Preço Total' : 'Total Price',
                        prefixIcon: const Icon(Icons.euro, color: Colors.green),
                        suffixText: '€',
                        filled: true,
                        fillColor: Colors.green.withOpacity(0.05),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      readOnly: true,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Explanation text
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locale == 'pt'
                                ? 'Calculado automaticamente: (dúzias × preço/dúzia) + (ovos individuais × preço/ovo)'
                                : 'Calculated automatically: (dozens × price/dozen) + (individual eggs × price/egg)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Email
                    TextFormField(
                      controller: _customerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
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
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Payment Section
                    Row(
                      children: [
                        Icon(Icons.payment, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          locale == 'pt' ? 'Pagamento' : 'Payment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Status
                    DropdownButtonFormField<PaymentStatus>(
                      value: _paymentStatus,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Estado do Pagamento' : 'Payment Status',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        helperText: locale == 'pt'
                            ? 'Pago = cliente levou e pagou, Pendente = cliente levou mas não pagou'
                            : 'Paid = customer took and paid, Pending = customer took but didn\'t pay',
                      ),
                      items: PaymentStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _paymentStatus = value;
                            // If marking as paid, set payment date to today
                            if (value == PaymentStatus.paid || value == PaymentStatus.advance) {
                              _paymentDate = DateTime.now();
                            }
                          });
                        }
                      },
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
                    child: Text(t('cancel')),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saveSale,
                    icon: const Icon(Icons.check),
                    label: Text(t('save')),
                  ),
                ],
              ),
            ),
          ],
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
      date: AppDateUtils.toIsoDateString(_selectedDate),
      quantitySold: quantity,
      pricePerEgg: pricePerEgg,
      pricePerDozen: pricePerDozen,
      customerName: customerName.isEmpty ? null : customerName,
      customerEmail: customerEmail.isEmpty ? null : customerEmail,
      customerPhone: customerPhone.isEmpty ? null : customerPhone,
      notes: notes.isEmpty ? null : notes,
      paymentStatus: _paymentStatus,
      paymentDate: _paymentDate != null ? AppDateUtils.toIsoDateString(_paymentDate!) : null,
      isReservation: false, // Sales are never reservations (reservations are separate)
      reservationNotes: null,
      isLost: false, // New sales are never marked as lost initially
      createdAt: widget.existingSale?.createdAt ?? DateTime.now(),
    );

    context.read<SaleProvider>().saveSale(sale);

    Navigator.pop(context);
  }
}
