import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../state/app_state.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class ExpenseDialog extends StatefulWidget {
  final Expense? existingExpense;

  const ExpenseDialog({super.key, this.existingExpense});

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
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
                    widget.existingExpense != null
                        ? t('edit_expense')
                        : t('add_expense'),
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

                  // Category
                  DropdownButtonFormField<ExpenseCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: t('expense_category'),
                      prefixIcon: const Icon(Icons.category),
                      border: const OutlineInputBorder(),
                    ),
                    items: ExpenseCategory.values.map((category) {
                      IconData icon;
                      Color color;
                      switch (category) {
                        case ExpenseCategory.feed:
                          icon = Icons.grass;
                          color = Colors.green;
                          break;
                        case ExpenseCategory.maintenance:
                          icon = Icons.build;
                          color = Colors.orange;
                          break;
                        case ExpenseCategory.equipment:
                          icon = Icons.hardware;
                          color = Colors.purple;
                          break;
                        case ExpenseCategory.utilities:
                          icon = Icons.electrical_services;
                          color = Colors.amber;
                          break;
                        case ExpenseCategory.other:
                          icon = Icons.more_horiz;
                          color = Colors.grey;
                          break;
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
                    onChanged: (value) {
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
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                      }
                      if (double.tryParse(value) == null) {
                        return locale == 'pt' ? 'Valor inválido' : 'Invalid value';
                      }
                      if (double.parse(value) <= 0) {
                        return locale == 'pt' ? 'Deve ser maior que zero' : 'Must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: '${t('description')} *',
                      prefixIcon: const Icon(Icons.description),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                      }
                      return null;
                    },
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
                        onPressed: _saveExpense,
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

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    final expense = Expense(
      id: widget.existingExpense?.id ?? const Uuid().v4(),
      date: _dateToString(_selectedDate),
      category: _selectedCategory,
      amount: amount,
      description: description,
      notes: notes.isEmpty ? null : notes,
      createdAt: widget.existingExpense?.createdAt ?? DateTime.now(),
    );

    Provider.of<AppState>(context, listen: false).saveExpense(expense);

    Navigator.pop(context);
  }
}
