import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Profile & Settings',
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email ?? 'Guest User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Egg Farmer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user?.createdAt != null)
                      Text(
                        'Member since ${_formatDate(DateTime.parse(user!.createdAt))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
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
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.red.shade50
                  : Colors.red.shade900.withOpacity(0.2),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.red.shade700
                      : Colors.red.shade300,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red.shade700
                        : Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Sign out of your account'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.red.shade700
                      : Colors.red.shade300,
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to sign out?'),
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
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await Supabase.instance.client.auth.signOut();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
