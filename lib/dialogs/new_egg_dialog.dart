import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/egg.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class NewEggDialog extends StatefulWidget {
  const NewEggDialog({super.key});

  @override
  State<NewEggDialog> createState() => _NewEggDialogState();
}

class _NewEggDialogState extends State<NewEggDialog> {
  final _tagCtl = TextEditingController();
  final _weightCtl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    return AlertDialog(
      title: Text(t('new_egg_record')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _tagCtl, decoration: InputDecoration(labelText: t('tag_label'))),
          TextField(controller: _weightCtl, decoration: InputDecoration(labelText: t('weight_label')), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
        ElevatedButton(
          onPressed: () {
            final eggProvider = context.read<EggProvider>();
            final nextId = eggProvider.nextId;
            final weight = int.tryParse(_weightCtl.text);
            eggProvider.addEgg(Egg(
              id: nextId,
              tag: _tagCtl.text.isNotEmpty ? _tagCtl.text : 'Batch-$nextId',
              createdAt: DateTime.now(),
              weight: weight,
              synced: false,
            ));
            Navigator.pop(context);
          },
          child: Text(t('add')),
        ),
      ],
    );
  }
}
