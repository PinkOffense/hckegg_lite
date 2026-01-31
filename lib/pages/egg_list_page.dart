import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/eggs/presentation/providers/egg_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import '../widgets/gradient_fab.dart';
import '../dialogs/daily_record_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/daily_egg_record.dart';

class EggListPage extends StatefulWidget {
  const EggListPage({super.key});

  @override
  State<EggListPage> createState() => _EggListPageState();
}

class _EggListPageState extends State<EggListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final theme = Theme.of(context);

    return AppScaffold(
      title: locale == 'pt' ? 'Registos Diários' : 'Daily Records',
      body: Consumer<EggProvider>(
        builder: (context, eggProvider, _) {
          final records = _searchQuery.isEmpty
              ? eggProvider.records
              : eggProvider.search(_searchQuery);

          if (eggProvider.records.isEmpty) {
            return ChickenEmptyState(
              title: locale == 'pt' ? 'Sem Registos' : 'No Records Yet',
              message: locale == 'pt'
                  ? 'Registe a sua recolha diária de ovos'
                  : 'Track your daily egg collection',
              actionLabel: locale == 'pt' ? 'Adicionar Registo' : 'Add Record',
              onAction: () => showDialog(
                context: context,
                builder: (_) => const DailyRecordDialog(),
              ),
            );
          }

          return Column(
            children: [
              // Search Bar
              AppSearchBar(
                controller: _searchController,
                hintText: locale == 'pt' ? 'Pesquisar por data ou notas...' : 'Search by date or notes...',
                hasContent: _searchQuery.isNotEmpty,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),

              // Records List
              Expanded(
                child: records.isEmpty
                    ? SearchEmptyState(
                        query: _searchQuery,
                        locale: locale,
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _RecordCard(
                            record: record,
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => DailyRecordDialog(existingRecord: record),
                            ),
                            onDelete: () => _confirmDelete(context, eggProvider, record),
                          );
                        },
                      ),
              ),

              // Summary Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      label: 'Total',
                      value: '${eggProvider.totalEggsCollected}',
                      icon: Icons.egg,
                      color: theme.colorScheme.primary,
                    ),
                    _SummaryItem(
                      label: 'Consumed',
                      value: '${eggProvider.totalEggsConsumed}',
                      icon: Icons.restaurant,
                      color: Colors.orange,
                    ),
                    _SummaryItem(
                      label: 'Remaining',
                      value: '${eggProvider.totalEggsCollected - eggProvider.totalEggsConsumed}',
                      icon: Icons.inventory,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      fab: GradientFAB(
        extended: true,
        icon: Icons.add,
        label: locale == 'pt' ? 'Adicionar Registo' : 'Add Record',
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const DailyRecordDialog(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, EggProvider eggProvider, DailyEggRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete record for ${_formatDate(record.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      eggProvider.deleteRecord(record.date);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted')),
      );
    }
  }
}

class _RecordCard extends StatelessWidget {
  final DailyEggRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateFormatted = '${months[date.month - 1]} ${date.day}, ${date.year}';

    if (difference == 0) return 'Today • $dateFormatted';
    if (difference == 1) return 'Yesterday • $dateFormatted';
    return dateFormatted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Egg Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.egg,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${record.eggsCollected}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date
                  Expanded(
                    child: Text(
                      _formatDate(record.date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats Row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (record.eggsConsumed > 0)
                    _StatChip(
                      icon: Icons.restaurant,
                      label: '${record.eggsConsumed} eaten',
                      color: theme.colorScheme.tertiary,
                    ),
                  if (record.henCount != null)
                    _StatChip(
                      icon: Icons.flutter_dash,
                      label: '${record.henCount} hens',
                      color: Colors.orange,
                    ),
                ],
              ),

              // Notes
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.notes!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
