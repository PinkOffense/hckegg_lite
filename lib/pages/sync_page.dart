import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/app_scaffold.dart';
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

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return AppScaffold(
      title: t('sync'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Consumer<AppState>(builder: (context, state, _) {
          final q = state.syncQueue;
          return Column(
            children: [
              Card(
                child: ListTile(
                  title: Text(t('sync_status')),
                  subtitle: Text(
                    q.isEmpty
                        ? t('all_up_to_date')
                        : Translations.of(locale, 'item_pending', params: {'n': q.length.toString()}),
                  ),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: Text(t('sync_now')),
                    onPressed: q.isEmpty
                        ? null
                        : () async {
                      final snack = ScaffoldMessenger.of(context);
                      snack.showSnackBar(SnackBar(content: Text(t('starting_sync'))));
                      await state.performMockSync();
                      snack.showSnackBar(SnackBar(content: Text(t('sync_finished'))));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: q.isEmpty
                        ? Center(child: Text(t('no_queued_operations')))
                        : ListView.separated(
                      itemBuilder: (ctx, idx) {
                        final id = q[idx];
                        final egg = state.eggs.firstWhere((e) => e.id == id, orElse: () => Egg(id: id, tag: 'Unknown', createdAt: DateTime.now()));
                        return ListTile(
                          leading: CircleAvatar(child: Text(egg.id.toString())),
                          title: Text(egg.tag),
                          subtitle: Text('${t('local_only')} • ${formatDate(egg.createdAt)}'),
                          trailing: const Icon(Icons.pending, color: Colors.orange),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: q.length,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('sync_strategy'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }),
      ),
    );
  }
}
