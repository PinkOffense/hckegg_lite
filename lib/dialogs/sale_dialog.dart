import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../core/utils/validators.dart';
import '../models/egg_sale.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import 'base_dialog.dart';

class SaleDialog extends StatefulWidget {
  final EggSale? existingSale;

  const SaleDialog({super.key, this.existingSale});

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> with DialogStateMixin {
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
            DialogHeader(
              title: widget.existingSale != null
                  ? t('edit_sale')
                  : t('new_sale'),
              icon: Icons.point_of_sale,
              onClose: () => Navigator.of(context).pop(),
            ),
            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Error banner
                    if (hasError)
                      DialogErrorBanner(
                        message: errorMessage!,
                        onDismiss: clearError,
                      ),

                    // Date
                    InkWell(
                      onTap: isLoading ? null : () => _selectDate(context, locale),
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
                        labelText: '${t('quantity_eggs')} *',
                        prefixIcon: const Icon(Icons.egg),
                        suffixText: t('eggs_unit'),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      validator: FormValidators.positiveInt(locale: locale),
                    ),
                    const SizedBox(height: 16),

                    // Price per egg and dozen
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pricePerEggController,
                            decoration: InputDecoration(
                              labelText: '${t('price_per_egg')} *',
                              prefixIcon: const Icon(Icons.euro),
                              suffixText: '€',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: !isLoading,
                            validator: FormValidators.positiveNumber(locale: locale),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pricePerDozenController,
                            decoration: InputDecoration(
                              labelText: '${t('price_per_dozen')} *',
                              prefixIcon: const Icon(Icons.euro),
                              suffixText: '€',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: !isLoading,
                            validator: FormValidators.positiveNumber(locale: locale),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Price (calculated automatically)
                    TextFormField(
                      controller: _totalPriceController,
                      decoration: InputDecoration(
                        labelText: t('total_price'),
                        prefixIcon: const Icon(Icons.euro, color: Colors.green),
                        suffixText: '€',
                        filled: true,
                        fillColor: Colors.green.withValues(alpha: 0.05),
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
                            t('price_calc_explanation'),
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
                    DialogSectionHeader(
                      title: t('customer_info_optional'),
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Customer Name
                    TextFormField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: t('customer_name'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      enabled: !isLoading,
                      validator: FormValidators.maxLength(100, locale: locale),
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
                      enabled: !isLoading,
                      validator: FormValidators.email(locale: locale),
                    ),
                    const SizedBox(height: 16),

                    // Customer Phone
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: InputDecoration(
                        labelText: t('phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      validator: FormValidators.phone(locale: locale),
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
                      enabled: !isLoading,
                      validator: FormValidators.maxLength(500, locale: locale),
                    ),
                    const SizedBox(height: 24),

                    // Payment Section
                    DialogSectionHeader(
                      title: t('payment_section'),
                      icon: Icons.payment,
                    ),
                    const SizedBox(height: 16),

                    // Payment Status
                    DropdownButtonFormField<PaymentStatus>(
                      value: _paymentStatus,
                      decoration: InputDecoration(
                        labelText: t('payment_status_label'),
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        helperText: t('payment_helper_pending'),
                      ),
                      items: PaymentStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName(locale)),
                        );
                      }).toList(),
                      onChanged: isLoading ? null : (value) {
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
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _saveSale,
              cancelText: t('cancel'),
              saveText: t('save'),
              isLoading: isLoading,
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

    if (picked != null && mounted) {
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

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    final success = await executeSave(
      locale: locale,
      saveAction: () async {
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
          isReservation: false,
          reservationNotes: null,
          isLost: false,
          createdAt: widget.existingSale?.createdAt ?? DateTime.now(),
        );

        await context.read<SaleProvider>().saveSale(sale);
      },
      onSuccess: () {
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );

    if (!success && mounted) {
      // Error is already shown via setError in executeSave
    }
  }
}
