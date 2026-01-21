import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(t('app_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(t('dashboard')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: Text(t('egg_records')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/eggs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(t('sync')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/sync');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.red.shade700
                      : Colors.red.shade300,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(t('about_lite')),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: t('app_title'),
                  applicationVersion: '1.0.0',
                  children: [Text(t('offline_description'))],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
