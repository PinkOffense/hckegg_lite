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

class EggListPage extends StatefulWidget {
  const EggListPage({super.key});

  @override
  State<EggListPage> createState() => _EggListPageState();
}

class _EggListPageState extends State<EggListPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return AppScaffold(
      title: t('egg_records'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t('search_by_tag')),
              onChanged: (v) => setState(() => q = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Consumer<AppState>(builder: (context, state, _) {
                final list = state.search(q);
                if (list.isEmpty) return Center(child: Text(t('no_records_found')));
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final egg = list[idx];
                    return ListTile(
                      leading: CircleAvatar(child: Text(egg.id.toString())),
                      title: Text(egg.tag),
                      subtitle: Text('${egg.weight ?? '-'} g • ${formatDate(egg.createdAt)}'),
                      trailing: Icon(egg.synced ? Icons.cloud_done : Icons.cloud_upload, color: egg.synced ? Colors.green : Colors.orange),
                      onTap: () => Navigator.pushNamed(context, '/detail', arguments: {'id': egg.id}),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      fab: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showDialog(context: context, builder: (_) => const NewEggDialog()),
      ),
    );
  }
}
