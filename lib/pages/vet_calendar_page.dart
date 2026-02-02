import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vet_record.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../dialogs/vet_record_dialog.dart';
import '../dialogs/schedule_vet_visit_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/gradient_fab.dart';

class VetCalendarPage extends StatefulWidget {
  const VetCalendarPage({super.key});

  @override
  State<VetCalendarPage> createState() => _VetCalendarPageState();
}

class _VetCalendarPageState extends State<VetCalendarPage> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  bool _reminderShown = false;
  VetRecordProvider? _vetProvider;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the provider and add listener if not already done
    final vetProvider = Provider.of<VetRecordProvider>(context, listen: false);
    if (_vetProvider != vetProvider) {
      _vetProvider?.removeListener(_onDataChanged);
      _vetProvider = vetProvider;
      _vetProvider!.addListener(_onDataChanged);

      // Try to show reminder immediately if data is already loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTodayReminder();
      });
    }
  }

  @override
  void dispose() {
    _vetProvider?.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    // Try to show reminder when data changes (e.g., after loading)
    if (mounted && !_reminderShown) {
      _showTodayReminder();
    }
  }

  void _showTodayReminder() {
    if (_reminderShown || !mounted) return;

    final vetProvider = Provider.of<VetRecordProvider>(context, listen: false);

    // Wait for data to be loaded
    if (vetProvider.isLoading || vetProvider.state == VetState.initial) return;

    final todayAppointments = vetProvider.getTodayAppointments();
    if (todayAppointments.isEmpty) return;

    _reminderShown = true;
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    showDialog(
      context: context,
      builder: (context) => _TodayReminderDialog(
        appointments: todayAppointments,
        locale: locale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final vetProvider = Provider.of<VetRecordProvider>(context);

    final allRecords = vetProvider.getVetRecords();

    // Get records with scheduled actions
    final scheduledRecords = allRecords
        .where((r) => r.nextActionDate != null)
        .toList();

    // Group records by date
    final Map<String, List<VetRecord>> recordsByDate = {};
    for (final record in scheduledRecords) {
      final date = record.nextActionDate!;
      recordsByDate.putIfAbsent(date, () => []);
      recordsByDate[date]!.add(record);
    }

    // Get events for selected date
    final selectedDateStr = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : null;
    final selectedEvents = selectedDateStr != null ? recordsByDate[selectedDateStr] ?? [] : <VetRecord>[];

    // Get upcoming events (next 30 days)
    final now = DateTime.now();
    final upcomingEvents = scheduledRecords.where((r) {
      final date = DateTime.parse(r.nextActionDate!);
      return date.isAfter(now.subtract(const Duration(days: 1))) &&
          date.isBefore(now.add(const Duration(days: 30)));
    }).toList()
      ..sort((a, b) => a.nextActionDate!.compareTo(b.nextActionDate!));

    // Check if coming from hen health page
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final fromHenHealth = args?['fromHenHealth'] == true;

    return AppScaffold(
      title: locale == 'pt' ? 'Calendário Veterinário' : 'Vet Calendar',
      additionalActions: fromHenHealth
          ? [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: locale == 'pt' ? 'Voltar à Saúde' : 'Back to Health',
                onPressed: () => Navigator.pop(context),
              ),
            ]
          : null,
      fab: GradientFAB(
        extended: true,
        icon: Icons.add,
        label: t('schedule_visit'),
        onPressed: () => _scheduleVisit(context, _selectedDate),
      ),
      body: Column(
        children: [
          // Calendar Header
          Container(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: locale == 'pt' ? 'Mês anterior' : 'Previous month',
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                GestureDetector(
                  onTap: () => _selectMonth(context),
                  child: Text(
                    _formatMonth(_currentMonth, locale),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: locale == 'pt' ? 'Próximo mês' : 'Next month',
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Calendar Grid
          _buildCalendarGrid(theme, locale, recordsByDate),

          const Divider(height: 1),

          // Selected Date Events or Upcoming Events
          Expanded(
            child: _selectedDate != null
                ? _buildSelectedDateEvents(
                    theme, locale, t, selectedEvents, _selectedDate!)
                : _buildUpcomingEvents(theme, locale, t, upcomingEvents),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
      ThemeData theme, String locale, Map<String, List<VetRecord>> recordsByDate) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    final weekdayNames = locale == 'pt'
        ? ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: weekdayNames
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar days
          ...List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }

                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final hasEvents = recordsByDate.containsKey(dateStr);
                final eventCount = recordsByDate[dateStr]?.length ?? 0;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected = _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;
                final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primaryContainer
                                : hasEvents
                                    ? Colors.purple.withValues(alpha: 0.1)
                                    : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isToday || hasEvents
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : isPast && !hasEvents
                                      ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                                      : null,
                            ),
                          ),
                          if (hasEvents)
                            Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  eventCount > 3 ? 3 : eventCount,
                                  (i) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedDateEvents(ThemeData theme, String locale,
      String Function(String) t, List<VetRecord> events, DateTime date) {
    final formattedDate = _formatDate(date, locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                child: Text(locale == 'pt' ? 'Ver próximos' : 'View upcoming'),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        locale == 'pt'
                            ? 'Sem eventos agendados'
                            : 'No scheduled events',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _scheduleVisit(context, date),
                        icon: const Icon(Icons.add),
                        label: Text(
                          locale == 'pt' ? 'Agendar visita' : 'Schedule visit',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final record = events[index];
                    return _EventCard(
                      key: ValueKey(record.id),
                      record: record,
                      locale: locale,
                      onTap: () => _editRecord(context, record),
                      onDelete: () => _deleteRecord(context, record),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents(ThemeData theme, String locale,
      String Function(String) t, List<VetRecord> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            locale == 'pt' ? 'Próximas Visitas' : 'Upcoming Visits',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        locale == 'pt'
                            ? 'Nenhuma visita agendada'
                            : 'No visits scheduled',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _scheduleVisit(context, null),
                        icon: const Icon(Icons.add),
                        label: Text(
                          locale == 'pt' ? 'Agendar visita' : 'Schedule visit',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final record = events[index];
                    return _EventCard(
                      key: ValueKey('upcoming_${record.id}'),
                      record: record,
                      locale: locale,
                      showDate: true,
                      onTap: () => _editRecord(context, record),
                      onDelete: () => _deleteRecord(context, record),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _scheduleVisit(BuildContext context, DateTime? date) {
    showDialog(
      context: context,
      builder: (context) => ScheduleVetVisitDialog(initialDate: date),
    );
  }

  void _editRecord(BuildContext context, VetRecord record) {
    showDialog(
      context: context,
      builder: (context) => VetRecordDialog(existingRecord: record),
    );
  }

  void _deleteRecord(BuildContext context, VetRecord record) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Eliminar Agendamento' : 'Delete Appointment'),
        content: Text(
          locale == 'pt'
              ? 'Tem certeza que deseja eliminar este agendamento?'
              : 'Are you sure you want to delete this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<VetRecordProvider>().deleteVetRecord(record.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(locale == 'pt' ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final selected = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      locale: Locale(locale),
    );
    if (selected != null) {
      setState(() {
        _currentMonth = DateTime(selected.year, selected.month, 1);
      });
    }
  }

  String _formatMonth(DateTime date, String locale) {
    final months = locale == 'pt'
        ? [
            'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
            'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
          ]
        : [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date, String locale) {
    final months = locale == 'pt'
        ? ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (locale == 'pt') {
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

class _EventCard extends StatelessWidget {
  final VetRecord record;
  final String locale;
  final bool showDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EventCard({
    required this.record,
    required this.locale,
    this.showDate = false,
    required this.onTap,
    required this.onDelete,
  });

  // Extract time from notes field (format: "Hora: HH:MM" or "Time: HH:MM")
  String? _extractTime() {
    final notes = record.notes;
    if (notes == null) return null;

    // Try Portuguese format
    final ptMatch = RegExp(r'Hora:\s*(\d{1,2}:\d{2})').firstMatch(notes);
    if (ptMatch != null) return ptMatch.group(1);

    // Try English format
    final enMatch = RegExp(r'Time:\s*(\d{1,2}:\d{2})').firstMatch(notes);
    if (enMatch != null) return enMatch.group(1);

    return null;
  }

  // Extract vet name from notes field
  String? _extractVetName() {
    final notes = record.notes;
    if (notes == null) return null;

    // Try Portuguese format
    final ptMatch = RegExp(r'Veterinário:\s*([^|]+)').firstMatch(notes);
    if (ptMatch != null) return ptMatch.group(1)?.trim();

    // Try English format
    final enMatch = RegExp(r'Vet:\s*([^|]+)').firstMatch(notes);
    if (enMatch != null) return enMatch.group(1)?.trim();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData typeIcon;
    Color typeColor;
    switch (record.type) {
      case VetRecordType.vaccine:
        typeIcon = Icons.vaccines;
        typeColor = Colors.green;
        break;
      case VetRecordType.disease:
        typeIcon = Icons.sick;
        typeColor = Colors.red;
        break;
      case VetRecordType.treatment:
        typeIcon = Icons.healing;
        typeColor = Colors.blue;
        break;
      case VetRecordType.death:
        typeIcon = Icons.warning;
        typeColor = Colors.black;
        break;
      case VetRecordType.checkup:
        typeIcon = Icons.health_and_safety;
        typeColor = Colors.teal;
        break;
    }

    final nextDate = DateTime.parse(record.nextActionDate!);
    final now = DateTime.now();
    final daysUntil = nextDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    String daysText;
    Color daysColor;
    if (daysUntil < 0) {
      daysText = locale == 'pt' ? 'Atrasado' : 'Overdue';
      daysColor = Colors.red;
    } else if (daysUntil == 0) {
      daysText = locale == 'pt' ? 'Hoje' : 'Today';
      daysColor = Colors.orange;
    } else if (daysUntil == 1) {
      daysText = locale == 'pt' ? 'Amanhã' : 'Tomorrow';
      daysColor = Colors.orange;
    } else {
      daysText = locale == 'pt' ? 'Em $daysUntil dias' : 'In $daysUntil days';
      daysColor = Colors.green;
    }

    final appointmentTime = _extractTime();
    final vetName = _extractVetName();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.type.displayName(locale),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (appointmentTime != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  appointmentTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (vetName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: 12,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vetName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (showDate) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(nextDate, locale),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    // Show cost and hens if available
                    if (record.cost != null || record.hensAffected > 1) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (record.hensAffected > 1) ...[
                            Icon(
                              Icons.egg_alt,
                              size: 12,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${record.hensAffected}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (record.cost != null) ...[
                            Icon(
                              Icons.euro,
                              size: 12,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              record.cost!.toStringAsFixed(2),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: daysColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  daysText,
                  style: TextStyle(
                    color: daysColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red.withValues(alpha: 0.7),
                tooltip: locale == 'pt' ? 'Eliminar' : 'Delete',
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String locale) {
    final months = locale == 'pt'
        ? ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (locale == 'pt') {
      return '${date.day} ${months[date.month - 1]}';
    } else {
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

class _TodayReminderDialog extends StatelessWidget {
  final List<VetRecord> appointments;
  final String locale;

  const _TodayReminderDialog({
    required this.appointments,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_active, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              locale == 'pt' ? 'Lembrete de Hoje' : "Today's Reminder",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale == 'pt'
                  ? 'Tem ${appointments.length} agendamento${appointments.length > 1 ? 's' : ''} para hoje:'
                  : 'You have ${appointments.length} appointment${appointments.length > 1 ? 's' : ''} today:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...appointments.map((record) => _buildAppointmentTile(context, record)),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(locale == 'pt' ? 'Entendido' : 'Got it'),
        ),
      ],
    );
  }

  Widget _buildAppointmentTile(BuildContext context, VetRecord record) {
    final theme = Theme.of(context);

    IconData typeIcon;
    Color typeColor;
    switch (record.type) {
      case VetRecordType.vaccine:
        typeIcon = Icons.vaccines;
        typeColor = Colors.green;
        break;
      case VetRecordType.disease:
        typeIcon = Icons.sick;
        typeColor = Colors.red;
        break;
      case VetRecordType.treatment:
        typeIcon = Icons.healing;
        typeColor = Colors.blue;
        break;
      case VetRecordType.death:
        typeIcon = Icons.warning;
        typeColor = Colors.black;
        break;
      case VetRecordType.checkup:
        typeIcon = Icons.health_and_safety;
        typeColor = Colors.teal;
        break;
    }

    // Extract time from notes
    String? time;
    if (record.notes != null) {
      final ptMatch = RegExp(r'Hora:\s*(\d{1,2}:\d{2})').firstMatch(record.notes!);
      if (ptMatch != null) {
        time = ptMatch.group(1);
      } else {
        final enMatch = RegExp(r'Time:\s*(\d{1,2}:\d{2})').firstMatch(record.notes!);
        if (enMatch != null) time = enMatch.group(1);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(typeIcon, color: typeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type.displayName(locale),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (time != null)
                  Text(
                    '${locale == 'pt' ? 'Hora' : 'Time'}: $time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                Text(
                  record.description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
