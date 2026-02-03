import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/vet_record.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../dialogs/vet_record_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/search_bar.dart';

class HenHealthPage extends StatefulWidget {
  const HenHealthPage({super.key});

  @override
  State<HenHealthPage> createState() => _HenHealthPageState();
}

class _HenHealthPageState extends State<HenHealthPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final vetProvider = Provider.of<VetRecordProvider>(context);

    final allRecords = vetProvider.getVetRecords();

    // Use cached statistics from provider
    final totalRecords = vetProvider.totalVetRecords;
    final totalDeaths = vetProvider.totalDeaths;
    final totalVetCosts = vetProvider.totalVetCosts;
    final upcomingActions = vetProvider.upcomingActionsCount;

    // Loading state
    if (vetProvider.isLoading && allRecords.isEmpty) {
      return AppScaffold(
        title: t('hen_health'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (vetProvider.hasError && allRecords.isEmpty) {
      return AppScaffold(
        title: t('hen_health'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                t('error_loading_records'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => vetProvider.loadRecords(),
                icon: const Icon(Icons.refresh),
                label: Text(t('try_again')),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: t('hen_health'),
      fab: GradientFAB(
        extended: true,
        icon: Icons.add,
        label: t('add_vet_record'),
        onPressed: () => _addRecord(context),
      ),
      body: Column(
        children: [
          // Health Overview Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('health_overview'),
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
                      label: t('total_records'),
                      value: totalRecords.toString(),
                      color: Colors.blue,
                    ),
                    _HealthStat(
                      icon: Icons.warning_amber,
                      label: t('deaths'),
                      value: totalDeaths.toString(),
                      color: Colors.red,
                    ),
                    _HealthStat(
                      icon: Icons.euro,
                      label: t('vet_costs'),
                      value: '€${totalVetCosts.toStringAsFixed(2)}',
                      color: Colors.orange,
                    ),
                    GestureDetector(
                      onTap: () => context.push('/vet-calendar'),
                      child: _HealthStat(
                        icon: Icons.event,
                        label: t('upcoming_actions'),
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

          // Search Bar (only if there are records)
          if (allRecords.isNotEmpty)
            AppSearchBar(
              controller: _searchController,
              hintText: t('search_records'),
              hasContent: _searchQuery.isNotEmpty,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onChanged: _onSearchChanged,
            ),

          const SizedBox(height: 8),

          // Records List
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredRecords = _searchQuery.isEmpty
                    ? allRecords
                    : vetProvider.search(_searchQuery);

                if (allRecords.isEmpty) {
                  return ChickenEmptyState(
                    title: t('no_vet_records'),
                    message: t('no_vet_records_msg'),
                    actionLabel: t('add_vet_record'),
                    onAction: () => _addRecord(context),
                  );
                }

                if (filteredRecords.isEmpty && _searchQuery.isNotEmpty) {
                  return SearchEmptyState(
                    query: _searchQuery,
                    locale: locale,
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return _VetRecordCard(
                      key: ValueKey(record.id),
                      record: record,
                      locale: locale,
                      onTap: () => _editRecord(context, record),
                      onDelete: () => _deleteRecord(context, record, t),
                    );
                  },
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
              context.read<VetRecordProvider>().deleteVetRecord(record.id);
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
        color: color.withValues(alpha: 0.1),
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
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
    super.key,
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
                      color: typeColor.withValues(alpha: 0.1),
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
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Severity Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
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
                    tooltip: Translations.of(locale, 'delete'),
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
                    label: '${record.hensAffected} ${Translations.of(locale, 'hens_unit')}',
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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.purple),
                      const SizedBox(width: 6),
                      Text(
                        '${Translations.of(locale, 'next_action')}: ${_formatDate(DateTime.parse(record.nextActionDate!), locale)}',
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
                  '${Translations.of(locale, 'notes')}: ${record.notes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
