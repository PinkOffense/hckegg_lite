import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../core/utils/validators.dart';
import '../models/expense.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import 'base_dialog.dart';

class ExpenseDialog extends StatefulWidget {
  final Expense? existingExpense;

  const ExpenseDialog({super.key, this.existingExpense});

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> with DialogStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;

  @override
  void initState() {
    super.initState();

    if (widget.existingExpense != null) {
      // Editing existing expense
      _selectedDate = DateTime.parse(widget.existingExpense!.date);
      _selectedCategory = widget.existingExpense!.category;
      _amountController.text = widget.existingExpense!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.existingExpense!.description;
      _notesController.text = widget.existingExpense!.notes ?? '';
    } else {
      // New expense
      _selectedDate = DateTime.now();
      _selectedCategory = ExpenseCategory.feed;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            DialogHeader(
              title: widget.existingExpense != null ? t('edit_expense') : t('add_expense'),
              icon: Icons.account_balance_wallet,
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
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: t('expense_category'),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: ExpenseCategory.values.map((category) {
                        IconData icon;
                        Color color;
                        switch (category) {
                          case ExpenseCategory.feed:
                            icon = Icons.grass;
                            color = Colors.green;
                          case ExpenseCategory.maintenance:
                            icon = Icons.build;
                            color = Colors.orange;
                          case ExpenseCategory.equipment:
                            icon = Icons.hardware;
                            color = Colors.purple;
                          case ExpenseCategory.utilities:
                            icon = Icons.electrical_services;
                            color = Colors.amber;
                          case ExpenseCategory.other:
                            icon = Icons.more_horiz;
                            color = Colors.grey;
                        }
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: color),
                              const SizedBox(width: 12),
                              Text(category.displayName(locale)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading ? null : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: '${t('amount')} *',
                        prefixIcon: const Icon(Icons.euro),
                        suffixText: '€',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isLoading,
                      validator: FormValidators.positiveNumber(locale: locale),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: '${t('description')} *',
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                      enabled: !isLoading,
                      validator: FormValidators.combine([
                        FormValidators.required(locale: locale),
                        FormValidators.maxLength(500, locale: locale),
                      ]),
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
                  ],
                ),
              ),
            ),
            // Footer with buttons
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _saveExpense,
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    await executeSave(
      locale: locale,
      saveAction: () async {
        final amount = double.parse(_amountController.text);
        final description = _descriptionController.text.trim();
        final notes = _notesController.text.trim();

        final expense = Expense(
          id: widget.existingExpense?.id ?? const Uuid().v4(),
          date: AppDateUtils.toIsoDateString(_selectedDate),
          category: _selectedCategory,
          amount: amount,
          description: description,
          notes: notes.isEmpty ? null : notes,
          createdAt: widget.existingExpense?.createdAt ?? DateTime.now(),
        );

        await context.read<ExpenseProvider>().saveExpense(expense);
      },
      onSuccess: () {
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }
}
