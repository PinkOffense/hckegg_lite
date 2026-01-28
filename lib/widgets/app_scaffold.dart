import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_provider.dart';
import '../services/logout_manager.dart';
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

  /// Handle sign out - sign out from Supabase and clear navigation stack
  Future<void> _handleSignOut(BuildContext context) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final navigator = Navigator.of(context);

    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale == 'pt' ? 'Terminar Sessão?' : 'Sign Out?'),
        content: Text(
          locale == 'pt'
              ? 'Tem a certeza que deseja sair?'
              : 'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              locale == 'pt' ? 'Sair' : 'Sign Out',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    // Clear all provider data to prevent data leakage
    LogoutManager.instance().clearAllProviders(context);

    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();

    // Clear the navigation stack to go back to AuthGate (which shows LoginPage)
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
        ),
        elevation: 0,
        actions: isSmallScreen
            ? _buildMobileActions(context, locale, themeProvider)
            : _buildDesktopActions(context, locale, themeProvider),
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: fab,
    );
  }

  List<Widget> _buildMobileActions(BuildContext context, String locale, ThemeProvider themeProvider) {
    return [
      if (additionalActions != null) ...additionalActions!,
      IconButton(
        tooltip: locale == 'pt' ? 'Calendário' : 'Calendar',
        icon: const Icon(Icons.calendar_month),
        onPressed: () => Navigator.pushNamed(context, '/vet-calendar'),
      ),
      PopupMenuButton<String>(
        tooltip: locale == 'pt' ? 'Mais opções' : 'More options',
        icon: const Icon(Icons.more_vert),
        onSelected: (String value) async {
          switch (value) {
            case 'language_en':
              Provider.of<LocaleProvider>(context, listen: false).setLocale('en');
              break;
            case 'language_pt':
              Provider.of<LocaleProvider>(context, listen: false).setLocale('pt');
              break;
            case 'toggle_theme':
              themeProvider.toggleTheme();
              break;
            case 'sign_out':
              await _handleSignOut(context);
              break;
            case 'profile':
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                locale == 'pt' ? 'Idioma' : 'Language',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'language_en',
              child: Row(
                children: [
                  if (localeProvider.code == 'en')
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  const Text('English'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'language_pt',
              child: Row(
                children: [
                  if (localeProvider.code == 'pt')
                    const Icon(Icons.check, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  const Text('Português'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'toggle_theme',
              child: Row(
                children: [
                  Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    themeProvider.isDarkMode
                        ? (locale == 'pt' ? 'Modo Claro' : 'Light Mode')
                        : (locale == 'pt' ? 'Modo Escuro' : 'Dark Mode'),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 18),
                  const SizedBox(width: 8),
                  Text(locale == 'pt' ? 'Perfil' : 'Profile'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'sign_out',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    locale == 'pt' ? 'Terminar Sessão' : 'Sign Out',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context, String locale, ThemeProvider themeProvider) {
    return [
      if (additionalActions != null) ...additionalActions!,
      IconButton(
        tooltip: locale == 'pt' ? 'Calendário' : 'Calendar',
        icon: const Icon(Icons.calendar_month),
        onPressed: () => Navigator.pushNamed(context, '/vet-calendar'),
      ),
      PopupMenuButton<String>(
        tooltip: locale == 'pt' ? 'Idioma' : 'Language',
        icon: const Icon(Icons.language),
        onSelected: (String languageCode) {
          Provider.of<LocaleProvider>(context, listen: false).setLocale(languageCode);
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
      IconButton(
        tooltip: themeProvider.isDarkMode
            ? (locale == 'pt' ? 'Modo Claro' : 'Light Mode')
            : (locale == 'pt' ? 'Modo Escuro' : 'Dark Mode'),
        icon: Icon(
          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        ),
        onPressed: () => themeProvider.toggleTheme(),
      ),
      IconButton(
        tooltip: locale == 'pt' ? 'Terminar Sessão' : 'Sign Out',
        icon: const Icon(Icons.logout),
        onPressed: () => _handleSignOut(context),
      ),
      IconButton(
        tooltip: locale == 'pt' ? 'Perfil' : 'Profile',
        icon: const Icon(Icons.account_circle),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
    ];
  }
}
