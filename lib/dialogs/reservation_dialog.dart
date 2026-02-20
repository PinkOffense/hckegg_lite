import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../models/egg_reservation.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class ReservationDialog extends StatefulWidget {
  final EggReservation? existingReservation;

  const ReservationDialog({super.key, this.existingReservation});

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _pricePerEggController = TextEditingController();
  final _pricePerDozenController = TextEditingController();

  late DateTime _reservationDate;
  DateTime? _pickupDate;
  bool _lockPrice = false;
  bool _updatingPrices = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingReservation != null) {
      // Editing existing reservation
      _reservationDate = DateTime.parse(widget.existingReservation!.date);
      _pickupDate = widget.existingReservation!.pickupDate != null
          ? DateTime.parse(widget.existingReservation!.pickupDate!)
          : null;
      _quantityController.text = widget.existingReservation!.quantity.toString();
      _customerNameController.text = widget.existingReservation!.customerName ?? '';
      _customerEmailController.text = widget.existingReservation!.customerEmail ?? '';
      _customerPhoneController.text = widget.existingReservation!.customerPhone ?? '';
      _notesController.text = widget.existingReservation!.notes ?? '';

      if (widget.existingReservation!.pricePerEgg != null) {
        _lockPrice = true;
        _pricePerEggController.text = widget.existingReservation!.pricePerEgg!.toStringAsFixed(2);
        _pricePerDozenController.text = widget.existingReservation!.pricePerDozen!.toStringAsFixed(2);
      }
    } else {
      // New reservation
      _reservationDate = DateTime.now();
      _pricePerEggController.text = '0.50';
      _pricePerDozenController.text = '6.00';
    }

    // Add listeners for price sync
    _pricePerEggController.addListener(_onPricePerEggChanged);
    _pricePerDozenController.addListener(_onPricePerDozenChanged);
  }

  void _onPricePerEggChanged() {
    if (_updatingPrices || !_lockPrice) return;

    final text = _pricePerEggController.text;
    final price = double.tryParse(text);

    if (price != null && price > 0) {
      _updatingPrices = true;
      final dozenPrice = price * 12;
      _pricePerDozenController.text = dozenPrice.toStringAsFixed(2);
      _updatingPrices = false;
    }
  }

  void _onPricePerDozenChanged() {
    if (_updatingPrices || !_lockPrice) return;

    final text = _pricePerDozenController.text;
    final price = double.tryParse(text);

    if (price != null && price > 0) {
      _updatingPrices = true;
      final eggPrice = price / 12;
      _pricePerEggController.text = eggPrice.toStringAsFixed(2);
      _updatingPrices = false;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _pricePerEggController.dispose();
    _pricePerDozenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_add,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingReservation != null
                          ? t('edit_reservation')
                          : t('new_reservation'),
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
                    // Reservation Date
                    InkWell(
                      onTap: () => _selectReservationDate(context, locale),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: t('reservation_date'),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _formatDate(_reservationDate, locale),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pickup Date (optional)
                    InkWell(
                      onTap: () => _selectPickupDate(context, locale),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText:
                              '${t('pickup_date')} (${t('optional')})',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_pickupDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() => _pickupDate = null);
                                  },
                                ),
                              const Icon(Icons.event),
                            ],
                          ),
                        ),
                        child: Text(
                          _pickupDate != null
                              ? _formatDate(_pickupDate!, locale)
                              : t('not_set'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _pickupDate == null ? Colors.grey.shade600 : null,
                          ),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t('required_field');
                        }
                        if (int.tryParse(value) == null) {
                          return t('invalid_value');
                        }
                        if (int.parse(value) <= 0) {
                          return t('must_be_greater');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Customer Information Section
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          t('customer_information'),
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
                        labelText: '${t('customer_name')} *',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t('required_field');
                        }
                        return null;
                      },
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

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText:
                            '${t('notes_optional')} (${t('optional')})',
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Lock Price Section
                    Card(
                      child: SwitchListTile(
                        title: Text(t('lock_price')),
                        subtitle: Text(
                          t('lock_price_desc'),
                        ),
                        value: _lockPrice,
                        onChanged: (value) {
                          setState(() => _lockPrice = value);
                        },
                        secondary: Icon(
                          Icons.lock,
                          color: _lockPrice ? theme.colorScheme.primary : Colors.grey,
                        ),
                      ),
                    ),

                    // Price fields (shown only if lock price is enabled)
                    if (_lockPrice) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pricePerEggController,
                              decoration: InputDecoration(
                                labelText: t('price_per_egg'),
                                prefixIcon: const Icon(Icons.euro),
                                suffixText: '€',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pricePerDozenController,
                              decoration: InputDecoration(
                                labelText: t('price_per_dozen'),
                                prefixIcon: const Icon(Icons.euro),
                                suffixText: '€',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                    onPressed: _saveReservation,
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

  Future<void> _selectReservationDate(BuildContext context, String locale) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reservationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: Locale(locale),
    );

    if (picked != null) {
      setState(() => _reservationDate = picked);
    }
  }

  Future<void> _selectPickupDate(BuildContext context, String locale) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: Locale(locale),
    );

    if (picked != null) {
      setState(() => _pickupDate = picked);
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

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final customerName = _customerNameController.text.trim();
    final customerEmail = _customerEmailController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    final notes = _notesController.text.trim();

    final reservation = EggReservation(
      id: widget.existingReservation?.id ?? const Uuid().v4(),
      date: AppDateUtils.toIsoDateString(_reservationDate),
      pickupDate: _pickupDate != null ? AppDateUtils.toIsoDateString(_pickupDate!) : null,
      quantity: quantity,
      customerName: customerName.isEmpty ? null : customerName,
      customerEmail: customerEmail.isEmpty ? null : customerEmail,
      customerPhone: customerPhone.isEmpty ? null : customerPhone,
      notes: notes.isEmpty ? null : notes,
      pricePerEgg: _lockPrice ? double.tryParse(_pricePerEggController.text) : null,
      pricePerDozen: _lockPrice ? double.tryParse(_pricePerDozenController.text) : null,
      createdAt: widget.existingReservation?.createdAt ?? DateTime.now(),
    );

    try {
      final provider = context.read<ReservationProvider>();
      await provider.saveReservation(reservation);

      if (mounted) {
        // Check if provider has error
        if (provider.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao guardar: ${provider.error ?? "Erro desconhecido"}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
