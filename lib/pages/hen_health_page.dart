import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vet_record.dart';
import '../state/app_state.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../dialogs/vet_record_dialog.dart';
import '../widgets/app_scaffold.dart';

class HenHealthPage extends StatefulWidget {
  const HenHealthPage({super.key});

  @override
  State<HenHealthPage> createState() => _HenHealthPageState();
}

class _HenHealthPageState extends State<HenHealthPage> {
  VetRecordType? _filterType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final appState = Provider.of<AppState>(context);

    final allRecords = appState.getVetRecords();
    final filteredRecords = _filterType == null
        ? allRecords
        : allRecords.where((r) => r.type == _filterType).toList();

    // Calculate statistics
    final totalRecords = allRecords.length;
    final totalDeaths = allRecords.where((r) => r.type == VetRecordType.death).length;
    final totalHensAffected = allRecords.fold(0, (sum, r) => sum + r.hensAffected);
    final totalVetCosts = allRecords.fold(0.0, (sum, r) => sum + (r.cost ?? 0.0));
    final upcomingActions = allRecords
        .where((r) => r.nextActionDate != null)
        .where((r) {
          final nextDate = DateTime.parse(r.nextActionDate!);
          return nextDate.isAfter(DateTime.now());
        })
        .length;

    return AppScaffold(
      title: t('hen_health'),
      additionalActions: [
        // Calendar button
        IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: locale == 'pt' ? 'Calendário' : 'Calendar',
          onPressed: () => Navigator.pushNamed(context, '/vet-calendar'),
        ),
        // Filter button
        PopupMenuButton<VetRecordType?>(
          icon: Icon(
            _filterType == null ? Icons.filter_list : Icons.filter_alt,
            color: _filterType == null ? null : theme.colorScheme.primary,
          ),
          tooltip: locale == 'pt' ? 'Filtrar' : 'Filter',
          onSelected: (type) {
            setState(() => _filterType = type);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: null,
              child: Text(locale == 'pt' ? 'Todos' : 'All'),
            ),
            const PopupMenuDivider(),
            ...VetRecordType.values.map((type) {
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
              return PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Text(type.displayName(locale)),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => _addRecord(context),
        icon: const Icon(Icons.add),
        label: Text(t('add_vet_record')),
      ),
      body: Column(
        children: [
          // Health Overview Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale == 'pt' ? 'Panorama de Saúde' : 'Health Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _HealthStat(
                      icon: Icons.medical_information,
                      label: locale == 'pt' ? 'Total de Registos' : 'Total Records',
                      value: totalRecords.toString(),
                      color: Colors.blue,
                    ),
                    _HealthStat(
                      icon: Icons.warning_amber,
                      label: locale == 'pt' ? 'Mortes' : 'Deaths',
                      value: totalDeaths.toString(),
                      color: Colors.red,
                    ),
                    _HealthStat(
                      icon: Icons.euro,
                      label: locale == 'pt' ? 'Custos Veterinários' : 'Vet Costs',
                      value: '€${totalVetCosts.toStringAsFixed(2)}',
                      color: Colors.orange,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/vet-calendar'),
                      child: _HealthStat(
                        icon: Icons.event,
                        label: locale == 'pt' ? 'Ações Agendadas' : 'Upcoming Actions',
                        value: upcomingActions.toString(),
                        color: Colors.purple,
                        showArrow: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 64,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterType == null
                              ? (locale == 'pt'
                                  ? 'Nenhum registo veterinário'
                                  : 'No veterinary records')
                              : (locale == 'pt'
                                  ? 'Nenhum registo deste tipo'
                                  : 'No records of this type'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locale == 'pt'
                              ? 'Toque em + para adicionar'
                              : 'Tap + to add a record',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return _VetRecordCard(
                        record: record,
                        locale: locale,
                        onTap: () => _editRecord(context, record),
                        onDelete: () => _deleteRecord(context, record, t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addRecord(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VetRecordDialog(),
    );
  }

  void _editRecord(BuildContext context, VetRecord record) {
    showDialog(
      context: context,
      builder: (context) => VetRecordDialog(existingRecord: record),
    );
  }

  void _deleteRecord(BuildContext context, VetRecord record, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_record')),
        content: Text(t('delete_record_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).deleteVetRecord(record.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showArrow;

  const _HealthStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ],
      ),
    );
  }
}

class _VetRecordCard extends StatelessWidget {
  final VetRecord record;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VetRecordCard({
    required this.record,
    required this.locale,
    required this.onTap,
    required this.onDelete,
  });

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

    Color severityColor;
    switch (record.severity) {
      case VetRecordSeverity.low:
        severityColor = Colors.green;
        break;
      case VetRecordSeverity.medium:
        severityColor = Colors.orange;
        break;
      case VetRecordSeverity.high:
        severityColor = Colors.deepOrange;
        break;
      case VetRecordSeverity.critical:
        severityColor = Colors.red;
        break;
    }

    final date = DateTime.parse(record.date);
    final formattedDate = _formatDate(date, locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Type and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.type.displayName(locale),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Severity Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: severityColor, width: 1),
                    ),
                    child: Text(
                      record.severity.displayName(locale),
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: locale == 'pt' ? 'Eliminar' : 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                record.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              // Details Row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _DetailChip(
                    icon: Icons.numbers,
                    label: '${record.hensAffected} ${locale == 'pt' ? 'galinhas' : 'hens'}',
                  ),
                  if (record.cost != null)
                    _DetailChip(
                      icon: Icons.euro,
                      label: '€${record.cost!.toStringAsFixed(2)}',
                    ),
                  if (record.medication != null)
                    _DetailChip(
                      icon: Icons.medication,
                      label: record.medication!,
                    ),
                ],
              ),
              // Next Action Date
              if (record.nextActionDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.purple),
                      const SizedBox(width: 6),
                      Text(
                        '${locale == 'pt' ? 'Próxima ação' : 'Next action'}: ${_formatDate(DateTime.parse(record.nextActionDate!), locale)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Notes
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${locale == 'pt' ? 'Notas' : 'Notes'}: ${record.notes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
