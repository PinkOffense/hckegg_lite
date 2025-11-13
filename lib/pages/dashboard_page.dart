import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../dialogs/new_egg_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../models/egg.dart';

String formatDate(DateTime d) {
  final dt = d.toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return AppScaffold(
      title: t('dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AppState>(builder: (context, state, _) {
          final eggs = state.eggs;
          final total = eggs.length;
          final unsynced = state.syncQueue.length;
          final recent = eggs.take(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                _KpiRow(total: total, unsynced: unsynced),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _OverviewCard(recent: recent)),
                    const SizedBox(width: 12),
                    Expanded(child: _ChartCard(eggs: eggs)),
                  ],
                ),
                const SizedBox(height: 20),
                Align(alignment: Alignment.centerLeft, child: Text(t('quick_actions'), style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(t('new_egg')),
                      onPressed: () => showDialog(context: context, builder: (_) => const NewEggDialog()),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: Text(t('sync_now')),
                      onPressed: () async {
                        final s = Provider.of<AppState>(context, listen: false);
                        await s.performMockSync();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('sync_complete'))));
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
      fab: FloatingActionButton(
        child: const Icon(Icons.list),
        tooltip: Translations.of(locale, 'open_records'),
        onPressed: () => Navigator.pushNamed(context, '/eggs'),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final int total;
  final int unsynced;
  const _KpiRow({required this.total, required this.unsynced});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    return Row(
      children: [
        Expanded(child: _KpiCard(label: t('total_records'), value: '$total')),
        const SizedBox(width: 12),
        Expanded(child: _KpiCard(label: t('pending_sync'), value: '$unsynced')),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final List<Egg> recent;
  const _OverviewCard({required this.recent});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('recent_entries'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...recent.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(e.tag),
              subtitle: Text('${e.weight ?? '-'} g • ${formatDate(e.createdAt)}'),
            ))
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<Egg> eggs;
  const _ChartCard({required this.eggs});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    final weights = eggs.map((e) => (e.weight ?? 0).toDouble()).toList();
    final maxW = weights.isEmpty ? 1.0 : weights.reduce(max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(t('production_last'), style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weights.map((w) {
                  final height = (w / maxW) * 100 + 8;
                  final color = w > 100 ? Colors.green.shade400 : Colors.orange.shade400;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 6),
                          Text(w.toInt().toString(), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
