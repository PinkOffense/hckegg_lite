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

  const AppScaffold({super.key, required this.title, required this.body, this.fab});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
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
