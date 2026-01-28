import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/date_utils.dart';
import '../models/vet_record.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';

class ScheduleVetVisitDialog extends StatefulWidget {
  final DateTime? initialDate;
  final VetRecordType? initialType;

  const ScheduleVetVisitDialog({
    super.key,
    this.initialDate,
    this.initialType,
  });

  @override
  State<ScheduleVetVisitDialog> createState() => _ScheduleVetVisitDialogState();
}

class _ScheduleVetVisitDialogState extends State<ScheduleVetVisitDialog> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late VetRecordType _selectedType;
  final _notesController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _hensController = TextEditingController(text: '1');
  final _costController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedType = widget.initialType ?? VetRecordType.checkup;
    // Default time to 10:00 for better UX
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vetNameController.dispose();
    _hensController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: Locale(locale),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final notes = _notesController.text.trim();
    final vetName = _vetNameController.text.trim();
    final hens = int.tryParse(_hensController.text) ?? 1;
    final cost = double.tryParse(_costController.text.replaceAll(',', '.'));
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    // Build description with time and vet info
    String description;
    if (notes.isEmpty) {
      description = locale == 'pt'
          ? '${_selectedType.displayName(locale)} agendado'
          : 'Scheduled ${_selectedType.displayName(locale).toLowerCase()}';
    } else {
      description = notes;
    }

    // Add time to notes if selected
    String? fullNotes;
    final List<String> notesParts = [];
    if (_selectedTime != null) {
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      notesParts.add(locale == 'pt' ? 'Hora: $timeStr' : 'Time: $timeStr');
    }
    if (vetName.isNotEmpty) {
      notesParts.add(locale == 'pt' ? 'Veterinário: $vetName' : 'Vet: $vetName');
    }
    if (notesParts.isNotEmpty) {
      fullNotes = notesParts.join(' | ');
    }

    final record = VetRecord(
      id: const Uuid().v4(),
      date: AppDateUtils.toIsoDateString(DateTime.now()),
      type: _selectedType,
      hensAffected: hens,
      description: description,
      severity: _getSeverityForType(_selectedType),
      nextActionDate: AppDateUtils.toIsoDateString(_selectedDate),
      cost: cost,
      notes: fullNotes,
    );

    try {
      await context.read<VetRecordProvider>().saveVetRecord(record);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt' ? 'Erro ao guardar: $e' : 'Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  VetRecordSeverity _getSeverityForType(VetRecordType type) {
    switch (type) {
      case VetRecordType.vaccine:
      case VetRecordType.checkup:
        return VetRecordSeverity.low;
      case VetRecordType.treatment:
        return VetRecordSeverity.medium;
      case VetRecordType.disease:
        return VetRecordSeverity.high;
      case VetRecordType.death:
        return VetRecordSeverity.critical;
    }
  }

  String _formatDate(DateTime date, String locale) {
    final months = locale == 'pt'
        ? ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
        : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final weekdays = locale == 'pt'
        ? ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(TimeOfDay time, String locale) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getTypeIcon(VetRecordType type) {
    switch (type) {
      case VetRecordType.vaccine:
        return Icons.vaccines;
      case VetRecordType.disease:
        return Icons.sick;
      case VetRecordType.treatment:
        return Icons.healing;
      case VetRecordType.death:
        return Icons.warning;
      case VetRecordType.checkup:
        return Icons.health_and_safety;
    }
  }

  Color _getTypeColor(VetRecordType type) {
    switch (type) {
      case VetRecordType.vaccine:
        return Colors.green;
      case VetRecordType.disease:
        return Colors.red;
      case VetRecordType.treatment:
        return Colors.blue;
      case VetRecordType.death:
        return Colors.black;
      case VetRecordType.checkup:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(_selectedType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(_selectedType),
                        color: _getTypeColor(_selectedType),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        locale == 'pt' ? 'Agendar Visita' : 'Schedule Visit',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: locale == 'pt' ? 'Fechar' : 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Appointment Type Selection
                Text(
                  locale == 'pt' ? 'Tipo de Consulta' : 'Appointment Type',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VetRecordType.values
                      .where((t) => t != VetRecordType.death) // Exclude death from scheduling
                      .map((type) {
                    final isSelected = _selectedType == type;
                    final color = _getTypeColor(type);
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type);
                        }
                      },
                      avatar: Icon(
                        _getTypeIcon(type),
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      label: Text(type.displayName(locale)),
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Date and Time Row
                Row(
                  children: [
                    // Date Selector
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale == 'pt' ? 'Data' : 'Date',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(_selectedDate, locale),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time Selector
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _selectTime(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: theme.colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale == 'pt' ? 'Hora' : 'Time',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedTime != null
                                          ? _formatTime(_selectedTime!, locale)
                                          : (locale == 'pt' ? 'Definir' : 'Set'),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vet Name/Clinic
                TextFormField(
                  controller: _vetNameController,
                  decoration: InputDecoration(
                    labelText: locale == 'pt' ? 'Veterinário / Clínica' : 'Vet / Clinic',
                    hintText: locale == 'pt' ? 'Ex: Dr. Silva, Clínica Animal' : 'Ex: Dr. Smith, Animal Clinic',
                    prefixIcon: const Icon(Icons.local_hospital),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 8),

                // Hens and Cost Row
                Row(
                  children: [
                    // Hens Affected
                    Expanded(
                      child: TextFormField(
                        controller: _hensController,
                        decoration: InputDecoration(
                          labelText: locale == 'pt' ? 'Galinhas' : 'Hens',
                          prefixIcon: const Icon(Icons.egg_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale == 'pt' ? 'Obrigatório' : 'Required';
                          }
                          final n = int.tryParse(value);
                          if (n == null || n < 1) {
                            return locale == 'pt' ? 'Mínimo 1' : 'Min 1';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Estimated Cost
                    Expanded(
                      child: TextFormField(
                        controller: _costController,
                        decoration: InputDecoration(
                          labelText: locale == 'pt' ? 'Custo (€)' : 'Cost (€)',
                          prefixIcon: const Icon(Icons.euro),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reason/Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: locale == 'pt' ? 'Motivo / Notas' : 'Reason / Notes',
                    hintText: locale == 'pt'
                        ? 'Ex: Vacinação anual, checkup de rotina...'
                        : 'Ex: Annual vaccination, routine checkup...',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(locale == 'pt' ? 'Agendar' : 'Schedule'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
