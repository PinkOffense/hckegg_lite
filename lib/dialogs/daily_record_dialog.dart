import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../core/utils/validators.dart';
import '../models/daily_egg_record.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import 'base_dialog.dart';

class DailyRecordDialog extends StatefulWidget {
  final DailyEggRecord? existingRecord;

  const DailyRecordDialog({super.key, this.existingRecord});

  @override
  State<DailyRecordDialog> createState() => _DailyRecordDialogState();
}

class _DailyRecordDialogState extends State<DailyRecordDialog> with DialogStateMixin {
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
    if (isLoading) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);

      // Auto-load existing record if one exists for this date
      if (widget.existingRecord == null) {
        final eggProvider = context.read<EggProvider>();
        final dateStr = AppDateUtils.toIsoDateString(picked);
        final existingRecord = eggProvider.getRecordByDate(dateStr);

        if (existingRecord != null && mounted) {
          // Populate form with existing record data
          setState(() {
            _collectedController.text = existingRecord.eggsCollected.toString();
            _consumedController.text = existingRecord.eggsConsumed.toString();
            _henCountController.text = existingRecord.henCount?.toString() ?? '';
            _notesController.text = existingRecord.notes ?? '';
          });

          // Show info snackbar
          final locale = Provider.of<LocaleProvider>(context, listen: false).code;
          final t = (String k) => Translations.of(locale, k);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('record_loaded_for_date')),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date, String locale) {
    return AppDateUtils.formatFull(date, locale: locale);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    await executeSave(
      locale: locale,
      saveAction: () async {
        final eggProvider = context.read<EggProvider>();
        final dateStr = AppDateUtils.toIsoDateString(_selectedDate);

        // Check if there's an existing record for this date (to use its ID for update)
        final existingRecordForDate = widget.existingRecord ?? eggProvider.getRecordByDate(dateStr);

        final collected = int.parse(_collectedController.text);
        final consumed = int.tryParse(_consumedController.text) ?? 0;
        final henCount = int.tryParse(_henCountController.text);
        final notes = _notesController.text.trim();

        final record = DailyEggRecord(
          id: existingRecordForDate?.id ?? const Uuid().v4(),
          date: dateStr,
          eggsCollected: collected,
          eggsConsumed: consumed,
          henCount: henCount,
          notes: notes.isEmpty ? null : notes,
        );

        await eggProvider.saveRecord(record);
      },
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    // Get current collected value for consumed validation
    final collectedEggs = int.tryParse(_collectedController.text) ?? 0;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            DialogHeader(
              title: widget.existingRecord != null ? t('edit_daily_record') : t('add_daily_record'),
              icon: Icons.calendar_today,
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

                    // Date Selector
                    InkWell(
                      onTap: isLoading ? null : () => _selectDate(context),
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
                        hintText: t('how_many_eggs'),
                        prefixIcon: const Icon(Icons.egg),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !isLoading,
                      validator: FormValidators.nonNegativeInt(locale: locale),
                      onChanged: (_) => setState(() {}), // Trigger rebuild for consumed validation
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
                            enabled: !isLoading,
                            validator: collectedEggs > 0
                                ? FormValidators.consumedNotExceedCollected(
                                    collectedEggs: collectedEggs,
                                    locale: locale,
                                  )
                                : FormValidators.nonNegativeInt(required: false, locale: locale),
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
                            enabled: !isLoading,
                            validator: FormValidators.nonNegativeInt(required: false, locale: locale),
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
                        hintText: t('notes_hint_daily'),
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      enabled: !isLoading,
                      validator: FormValidators.maxLength(500, locale: locale),
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
                                  t('quick_summary'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Translations.of(locale, 'quick_summary_info', params: {'field': t('eggs_collected')}),
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
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _save,
              cancelText: t('cancel'),
              saveText: t('save'),
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
