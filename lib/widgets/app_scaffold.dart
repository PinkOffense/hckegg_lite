import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../state/theme_provider.dart';
import '../features/health/presentation/providers/vet_provider.dart';
import 'app_drawer.dart';

/// Responsive breakpoints
const double _tabletBreakpoint = 768;
const double _desktopBreakpoint = 1200;

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? fab;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;
    final isTablet = screenWidth >= _tabletBreakpoint && screenWidth < _desktopBreakpoint;

    // Desktop: permanent sidebar + constrained content
    if (isDesktop) {
      return Row(
        children: [
          SizedBox(
            width: 280,
            child: Material(
              elevation: 2,
              child: AppDrawer(embedded: true),
            ),
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title, style: const TextStyle(fontSize: 20)),
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: _buildDesktopActions(context, locale, themeProvider),
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: body,
                ),
              ),
              floatingActionButton: fab,
            ),
          ),
        ],
      );
    }

    // Tablet: drawer + constrained content
    if (isTablet) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontSize: 18)),
          elevation: 0,
          actions: _buildDesktopActions(context, locale, themeProvider),
        ),
        drawer: const AppDrawer(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: body,
          ),
        ),
        floatingActionButton: fab,
      );
    }

    // Mobile
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        elevation: 0,
        actions: _buildMobileActions(context, locale, themeProvider),
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: fab,
    );
  }

  List<Widget> _buildMobileActions(BuildContext context, String locale, ThemeProvider themeProvider) {
    final t = (String k) => Translations.of(locale, k);
    final vetProvider = Provider.of<VetRecordProvider>(context);
    final todayAppointments = vetProvider.getTodayAppointments();
    final hasAppointmentsToday = todayAppointments.isNotEmpty;

    return [
      if (additionalActions != null) ...additionalActions!,
      IconButton(
        tooltip: hasAppointmentsToday ? t('vet_today') : t('calendar'),
        icon: Badge(
          isLabelVisible: hasAppointmentsToday,
          label: Text('${todayAppointments.length}'),
          backgroundColor: Colors.red,
          child: Icon(
            Icons.calendar_month,
            color: hasAppointmentsToday ? Colors.red : null,
          ),
        ),
        onPressed: () => context.push('/vet-calendar'),
      ),
      PopupMenuButton<String>(
        tooltip: t('more_options'),
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
            case 'profile':
              context.push('/settings');
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                t('language'),
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
                    themeProvider.isDarkMode ? t('light_mode') : t('dark_mode'),
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
                  Text(t('profile')),
                ],
              ),
            ),
          ];
        },
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context, String locale, ThemeProvider themeProvider) {
    final t = (String k) => Translations.of(locale, k);
    final vetProvider = Provider.of<VetRecordProvider>(context);
    final todayAppointments = vetProvider.getTodayAppointments();
    final hasAppointmentsToday = todayAppointments.isNotEmpty;

    return [
      if (additionalActions != null) ...additionalActions!,
      IconButton(
        tooltip: hasAppointmentsToday ? t('vet_today') : t('calendar'),
        icon: Badge(
          isLabelVisible: hasAppointmentsToday,
          label: Text('${todayAppointments.length}'),
          backgroundColor: Colors.red,
          child: Icon(
            Icons.calendar_month,
            color: hasAppointmentsToday ? Colors.red : null,
          ),
        ),
        onPressed: () => context.push('/vet-calendar'),
      ),
      PopupMenuButton<String>(
        tooltip: t('language'),
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
        tooltip: themeProvider.isDarkMode ? t('light_mode') : t('dark_mode'),
        icon: Icon(
          themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        ),
        onPressed: () => themeProvider.toggleTheme(),
      ),
      IconButton(
        tooltip: t('profile'),
        icon: const Icon(Icons.account_circle),
        onPressed: () => context.push('/settings'),
      ),
    ];
  }
}
