import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../state/theme_provider.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final FloatingActionButton? fab;
  final List<Widget>? additionalActions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.fab,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          // Additional custom actions
          if (additionalActions != null) ...additionalActions!,
          // Language Selector
          PopupMenuButton<String>(
            tooltip: 'Language',
            icon: const Icon(Icons.language),
            onSelected: (String languageCode) {
              final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
              localeProvider.setLocale(languageCode);
            },
            itemBuilder: (BuildContext context) {
              final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
              return [
                PopupMenuItem<String>(
                  value: 'en',
                  child: Row(
                    children: [
                      if (localeProvider.code == 'en')
                        const Icon(Icons.check, size: 20),
                      if (localeProvider.code == 'en')
                        const SizedBox(width: 8),
                      const Text('English'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'pt',
                  child: Row(
                    children: [
                      if (localeProvider.code == 'pt')
                        const Icon(Icons.check, size: 20),
                      if (localeProvider.code == 'pt')
                        const SizedBox(width: 8),
                      const Text('Português'),
                    ],
                  ),
                ),
              ];
            },
          ),
          // Theme Toggle
          IconButton(
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          // Logout
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          // Profile
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: fab,
    );
  }
}
