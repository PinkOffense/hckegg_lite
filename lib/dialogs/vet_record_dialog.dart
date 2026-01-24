import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/vet_record.dart';
import '../state/app_state.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class VetRecordDialog extends StatefulWidget {
  final VetRecord? existingRecord;

  const VetRecordDialog({super.key, this.existingRecord});

  @override
  State<VetRecordDialog> createState() => _VetRecordDialogState();
}

class _VetRecordDialogState extends State<VetRecordDialog> {
  late DateTime _selectedDate;
  DateTime? _nextActionDate;
  VetRecordType _selectedType = VetRecordType.checkup;
  VetRecordSeverity _selectedSeverity = VetRecordSeverity.low;

  final _hensAffectedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.existingRecord != null) {
      final record = widget.existingRecord!;
      _selectedDate = DateTime.parse(record.date);
      _selectedType = record.type;
      _selectedSeverity = record.severity;
      _hensAffectedController.text = record.hensAffected.toString();
      _descriptionController.text = record.description;
      _medicationController.text = record.medication ?? '';
      _costController.text = record.cost?.toStringAsFixed(2) ?? '';
      _notesController.text = record.notes ?? '';
      _nextActionDate = record.nextActionDate != null
          ? DateTime.parse(record.nextActionDate!)
          : null;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _hensAffectedController.dispose();
    _descriptionController.dispose();
    _medicationController.dispose();
    _costController.dispose();
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

  Future<void> _selectNextActionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextActionDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _nextActionDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hensAffected = int.parse(_hensAffectedController.text);
    final description = _descriptionController.text.trim();
    final medication = _medicationController.text.trim();
    final cost = double.tryParse(_costController.text);
    final notes = _notesController.text.trim();

    final record = VetRecord(
      id: widget.existingRecord?.id ?? const Uuid().v4(),
      date: _dateToString(_selectedDate),
      type: _selectedType,
      hensAffected: hensAffected,
      description: description,
      medication: medication.isEmpty ? null : medication,
      cost: cost,
      nextActionDate: _nextActionDate != null ? _dateToString(_nextActionDate!) : null,
      notes: notes.isEmpty ? null : notes,
      severity: _selectedSeverity,
    );

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.saveVetRecord(record);
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

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 850),
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
                    Icons.medical_services,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingRecord != null ? t('edit_vet_record') : t('add_vet_record'),
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

                // Record Type
                DropdownButtonFormField<VetRecordType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: '${t('record_type')} *',
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: VetRecordType.values.map((type) {
                    IconData icon;
                    Color color;
                    switch (type) {
                      case VetRecordType.vaccine:
                        icon = Icons.vaccines;
                        color = Colors.green;
                        break;
                      case VetRecordType.disease:
                        icon = Icons.sick;
                        color = Colors.red;
                        break;
                      case VetRecordType.treatment:
                        icon = Icons.healing;
                        color = Colors.blue;
                        break;
                      case VetRecordType.death:
                        icon = Icons.warning;
                        color = Colors.black;
                        break;
                      case VetRecordType.checkup:
                        icon = Icons.health_and_safety;
                        color = Colors.teal;
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: color),
                          const SizedBox(width: 12),
                          Text(type.displayName(locale)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Hens Affected and Severity
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hensAffectedController,
                        decoration: InputDecoration(
                          labelText: '${t('hens_affected')} *',
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 1) {
                            return locale == 'pt' ? 'Mínimo 1' : 'Minimum 1';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<VetRecordSeverity>(
                        value: _selectedSeverity,
                        decoration: InputDecoration(
                          labelText: t('severity'),
                          prefixIcon: const Icon(Icons.priority_high),
                        ),
                        items: VetRecordSeverity.values.map((severity) {
                          Color color;
                          switch (severity) {
                            case VetRecordSeverity.low:
                              color = Colors.green;
                              break;
                            case VetRecordSeverity.medium:
                              color = Colors.orange;
                              break;
                            case VetRecordSeverity.high:
                              color = Colors.deepOrange;
                              break;
                            case VetRecordSeverity.critical:
                              color = Colors.red;
                              break;
                          }
                          return DropdownMenuItem(
                            value: severity,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(severity.displayName(locale)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSeverity = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description/Diagnosis
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '${t('diagnosis')} *',
                    hintText: locale == 'pt'
                        ? 'Ex: Vacinação anual, sintomas de...'
                        : 'Ex: Annual vaccination, symptoms of...',
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 300,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Medication
                TextFormField(
                  controller: _medicationController,
                  decoration: InputDecoration(
                    labelText: '${t('medication_used')} (${t('optional')})',
                    hintText: locale == 'pt' ? 'Nome do medicamento' : 'Medication name',
                    prefixIcon: const Icon(Icons.medication),
                  ),
                  maxLength: 150,
                ),
                const SizedBox(height: 16),

                // Cost
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: '${t('vet_expense')} (${t('optional')})',
                    hintText: '25.00',
                    prefixIcon: const Icon(Icons.euro),
                    suffixText: '€',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 20),

                // Next Action Date
                InkWell(
                  onTap: () => _selectNextActionDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '${t('next_action_date')} (${t('optional')})',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_nextActionDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => setState(() => _nextActionDate = null),
                            ),
                          const Icon(Icons.event),
                        ],
                      ),
                    ),
                    child: Text(
                      _nextActionDate != null
                          ? _formatDate(_nextActionDate!, locale)
                          : (locale == 'pt' ? 'Sem ação agendada' : 'No action scheduled'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _nextActionDate == null
                            ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: '${t('notes')} (${t('optional')})',
                    hintText: locale == 'pt'
                        ? 'Observações adicionais...'
                        : 'Additional observations...',
                    prefixIcon: const Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 500,
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
