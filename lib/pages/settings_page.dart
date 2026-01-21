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
                  await Supabase.instance.client.auth.signOut();
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
