import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/daily_egg_record.dart';
import '../state/app_state.dart';

class DailyRecordDialog extends StatefulWidget {
  final DailyEggRecord? existingRecord;

  const DailyRecordDialog({super.key, this.existingRecord});

  @override
  State<DailyRecordDialog> createState() => _DailyRecordDialogState();
}

class _DailyRecordDialogState extends State<DailyRecordDialog> {
  late DateTime _selectedDate;
  final _collectedController = TextEditingController();
  final _soldController = TextEditingController();
  final _consumedController = TextEditingController();
  final _priceController = TextEditingController();
  final _henCountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _selectedDate = DateTime.parse(record.date);
      _collectedController.text = record.eggsCollected.toString();
      _soldController.text = record.eggsSold.toString();
      _consumedController.text = record.eggsConsumed.toString();
      _priceController.text = record.pricePerEgg?.toStringAsFixed(2) ?? '';
      _henCountController.text = record.henCount?.toString() ?? '';
      _notesController.text = record.notes ?? '';
    } else {
      _selectedDate = DateTime.now();
      _collectedController.text = '';
      _soldController.text = '0';
      _consumedController.text = '0';
      _priceController.text = '';
    }
  }

  @override
  void dispose() {
    _collectedController.dispose();
    _soldController.dispose();
    _consumedController.dispose();
    _priceController.dispose();
    _henCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final collected = int.parse(_collectedController.text);
    final sold = int.tryParse(_soldController.text) ?? 0;
    final consumed = int.tryParse(_consumedController.text) ?? 0;
    final price = double.tryParse(_priceController.text);
    final henCount = int.tryParse(_henCountController.text);
    final notes = _notesController.text.trim();

    final record = DailyEggRecord(
      id: widget.existingRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateToString(_selectedDate),
      eggsCollected: collected,
      eggsSold: sold,
      eggsConsumed: consumed,
      pricePerEgg: price,
      henCount: henCount,
      notes: notes.isEmpty ? null : notes,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveRecord(record);

    Navigator.of(context).pop();
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.existingRecord != null ? 'Edit Record' : 'Add Daily Record'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: _save,
                child: Text(
                  'SAVE',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Date Selector
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _formatDate(_selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Eggs Collected (Required)
                TextFormField(
                  controller: _collectedController,
                  decoration: const InputDecoration(
                    labelText: 'Eggs Collected *',
                    hintText: 'How many eggs today?',
                    prefixIcon: Icon(Icons.egg),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of eggs collected';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Row: Sold and Consumed
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _soldController,
                        decoration: const InputDecoration(
                          labelText: 'Eggs Sold',
                          prefixIcon: Icon(Icons.sell),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _consumedController,
                        decoration: const InputDecoration(
                          labelText: 'Eggs Eaten',
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row: Price and Hen Count
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price per Egg',
                          hintText: '0.50',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _henCountController,
                        decoration: const InputDecoration(
                          labelText: 'Hen Count',
                          prefixIcon: Icon(Icons.flutter_dash),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Weather, hen behavior, etc.',
                    prefixIcon: Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 24),

                // Info Card
                Card(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Summary',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Only "Eggs Collected" is required\n'
                          '• Leave price empty if you don\'t track sales\n'
                          '• Notes help you remember important details',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
