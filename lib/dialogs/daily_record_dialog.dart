import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../models/daily_egg_record.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class DailyRecordDialog extends StatefulWidget {
  final DailyEggRecord? existingRecord;

  const DailyRecordDialog({super.key, this.existingRecord});

  @override
  State<DailyRecordDialog> createState() => _DailyRecordDialogState();
}

class _DailyRecordDialogState extends State<DailyRecordDialog> {
  late DateTime _selectedDate;
  final _collectedController = TextEditingController();
  final _consumedController = TextEditingController();
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
      _consumedController.text = record.eggsConsumed.toString();
      _henCountController.text = record.henCount?.toString() ?? '';
      _notesController.text = record.notes ?? '';
    } else {
      _selectedDate = DateTime.now();
      _collectedController.text = '';
      _consumedController.text = '0';
    }
  }

  @override
  void dispose() {
    _collectedController.dispose();
    _consumedController.dispose();
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

  String _formatDate(DateTime date, String locale) {
    return AppDateUtils.formatFull(date, locale: locale);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final collected = int.parse(_collectedController.text);
    final consumed = int.tryParse(_consumedController.text) ?? 0;
    final henCount = int.tryParse(_henCountController.text);
    final notes = _notesController.text.trim();

    final record = DailyEggRecord(
      id: widget.existingRecord?.id ?? const Uuid().v4(),
      date: AppDateUtils.toIsoDateString(_selectedDate),
      eggsCollected: collected,
      eggsConsumed: consumed,
      henCount: henCount,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      await context.read<EggProvider>().saveRecord(record);
      if (mounted) {
        Navigator.of(context).pop();
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
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingRecord != null ? t('edit_daily_record') : t('add_daily_record'),
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
                // Date Selector
                InkWell(
                  onTap: () => _selectDate(context),
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

                // Eggs Collected (Required)
                TextFormField(
                  controller: _collectedController,
                  decoration: InputDecoration(
                    labelText: '${t('eggs_collected')} *',
                    hintText: locale == 'pt' ? 'Quantos ovos hoje?' : 'How many eggs today?',
                    prefixIcon: const Icon(Icons.egg),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return locale == 'pt' ? 'Insira o número de ovos recolhidos' : 'Please enter number of eggs collected';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 0) {
                      return locale == 'pt' ? 'Insira um número válido' : 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Row: Consumed and Hen Count
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _consumedController,
                        decoration: InputDecoration(
                          labelText: t('eggs_consumed'),
                          prefixIcon: const Icon(Icons.restaurant),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _henCountController,
                        decoration: InputDecoration(
                          labelText: t('hen_count'),
                          prefixIcon: const Icon(Icons.flutter_dash),
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
                  decoration: InputDecoration(
                    labelText: '${t('notes')} (${t('optional')})',
                    hintText: locale == 'pt' ? 'Clima, comportamento das galinhas, etc.' : 'Weather, hen behavior, etc.',
                    prefixIcon: const Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 24),

                // Info Card
                Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                              locale == 'pt' ? 'Resumo Rápido' : 'Quick Summary',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locale == 'pt'
                              ? '• Apenas "${t('eggs_collected')}" é obrigatório\n'
                                '• Todos os outros campos são opcionais\n'
                                '• Use a página de vendas para registar vendas de ovos\n'
                                '• As notas ajudam a lembrar detalhes importantes'
                              : '• Only "${t('eggs_collected')}" is required\n'
                                '• All other fields are optional\n'
                                '• Use the sales page to record egg sales\n'
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
                    onPressed: _save,
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
}
