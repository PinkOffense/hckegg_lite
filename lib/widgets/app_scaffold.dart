import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/auth_service.dart';
import '../state/providers/providers.dart';
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

  /// Handle logout properly: clear providers and use AuthService
  Future<void> _handleLogout(BuildContext context) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Terminar Sessão?' : 'Sign Out?'),
        content: Text(
          locale == 'pt'
              ? 'Tem a certeza que deseja sair?'
              : 'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              locale == 'pt' ? 'Sair' : 'Sign Out',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Clear all provider data
    context.read<EggProvider>().clearData();
    context.read<EggRecordProvider>().clearData();
    context.read<ExpenseProvider>().clearData();
    context.read<VetRecordProvider>().clearData();
    context.read<SaleProvider>().clearData();
    context.read<ReservationProvider>().clearData();
    context.read<FeedStockProvider>().clearData();

    // Sign out using AuthService (handles Google sign-out too)
    final authService = AuthService(Supabase.instance.client);
    await authService.signOut();
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

  // Mobile: Show only calendar + overflow menu
  List<Widget> _buildMobileActions(BuildContext context, String locale, ThemeProvider themeProvider) {
    return [
      // Additional custom actions (if any)
      if (additionalActions != null) ...additionalActions!,
      // Calendar button
      IconButton(
        tooltip: locale == 'pt' ? 'Calendário' : 'Calendar',
        icon: const Icon(Icons.calendar_month),
        onPressed: () => Navigator.pushNamed(context, '/vet-calendar'),
      ),
      // Overflow menu with all other options
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
            case 'logout':
              await _handleLogout(context);
              break;
            case 'profile':
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
          return [
            // Language submenu header
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
            // Theme toggle
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
            // Profile
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
            // Logout
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18),
                  const SizedBox(width: 8),
                  Text(locale == 'pt' ? 'Sair' : 'Logout'),
                ],
              ),
            ),
          ];
        },
      ),
    ];
  }

  // Desktop: Show all actions
  List<Widget> _buildDesktopActions(BuildContext context, String locale, ThemeProvider themeProvider) {
    return [
      // Additional custom actions
      if (additionalActions != null) ...additionalActions!,
      // Calendar button
      IconButton(
        tooltip: locale == 'pt' ? 'Calendário' : 'Calendar',
        icon: const Icon(Icons.calendar_month),
        onPressed: () => Navigator.pushNamed(context, '/vet-calendar'),
      ),
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
        onPressed: () => _handleLogout(context),
      ),
      // Profile
      IconButton(
        tooltip: 'Profile',
        icon: const Icon(Icons.account_circle),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
    ];
  }
}
