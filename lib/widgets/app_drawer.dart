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
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? 'Guest',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Egg Farmer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
              leading: const Icon(Icons.sell),
              title: Text(locale == 'pt' ? 'Vendas' : 'Sales'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/sales');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: Text(locale == 'pt' ? 'Pagamentos' : 'Payments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/payments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(locale == 'pt' ? 'Reservas' : 'Reservations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/reservations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(t('expenses')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/expenses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: Text(t('hen_health')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/health');
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
