import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final locale = localeProvider.code;
    final t = (String k) => Translations.of(locale, k);

    return AppScaffold(
      title: t('settings'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud),
                title: Text(t('backend')),
                subtitle: Text(t('supabase_dialog')),
                onTap: () async {
                  showDialog(context: context, builder: (_) => AlertDialog(title: Text(t('configure_supabase')), content: Text(t('supabase_dialog'))));
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report),
                title: Text(t('crash_reporting')),
                subtitle: Text(t('crash_dialog')),
                onTap: () {
                  showDialog(context: context, builder: (_) => AlertDialog(title: Text(t('crash_reporting')), content: Text(t('crash_dialog'))));
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage),
                title: Text(t('local_db')),
                subtitle: const Text('Drift (SQLite)'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: Text(t('clear_local_mock_data')),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('clear_mock_not_impl'))));
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('language'), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(t('english')),
                          selected: localeProvider.code == 'en',
                          onSelected: (s) {
                            if (s) localeProvider.setLocale('en');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(t('portuguese')),
                          selected: localeProvider.code == 'pt',
                          onSelected: (s) {
                            if (s) localeProvider.setLocale('pt');
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
