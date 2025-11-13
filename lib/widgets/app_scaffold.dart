import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final FloatingActionButton? fab;

  const AppScaffold({super.key, required this.title, required this.body, this.fab});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: Translations.of(locale, 'open_sync_tooltip'),
            icon: const Icon(Icons.sync),
            onPressed: () => Navigator.pushNamed(context, '/sync'),
          ),
          IconButton(
            tooltip: Translations.of(locale, 'open_settings_tooltip'),
            icon: const Icon(Icons.settings),
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
