import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/egg.dart';
import '../state/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

String formatDate(DateTime d) {
  final dt = d.toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class EggDetailPage extends StatefulWidget {
  final int eggId;
  const EggDetailPage({super.key, required this.eggId});

  @override
  State<EggDetailPage> createState() => _EggDetailPageState();
}

class _EggDetailPageState extends State<EggDetailPage> {
  late Egg egg;
  final _weightCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final app = Provider.of<AppState>(context, listen: false);
    egg = app.eggs.firstWhere((e) => e.id == widget.eggId);
    _weightCtl.text = egg.weight?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return AppScaffold(
      title: '${t('record')} ${egg.tag}',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text(egg.tag, style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text('${t('created')}: ${formatDate(egg.createdAt)}'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t('weight_label')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  child: Text(t('save')),
                  onPressed: () {
                    final wt = int.tryParse(_weightCtl.text);
                    final updated = egg.copyWith(weight: wt, synced: false);
                    Provider.of<AppState>(context, listen: false).updateEgg(updated);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('saved_locally'))));
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  child: Text(t('mark_synced')),
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false).markSynced(egg.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('marked_synced'))));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
