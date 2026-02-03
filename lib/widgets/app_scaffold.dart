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
                actions: _buildDesktopActions(context),
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
          actions: _buildDesktopActions(context),
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
        actions: _buildMobileActions(context),
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: fab,
    );
  }

  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      if (additionalActions != null) ...additionalActions!,
      // Vet badge rebuilds independently via Consumer
      const _VetCalendarBadge(),
      // Menu button - reads theme/locale only when popup is opened
      _MobileMenuButton(onThemeToggle: () {
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      }),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context) {
    return [
      if (additionalActions != null) ...additionalActions!,
      const _VetCalendarBadge(),
      const _LanguageMenuButton(),
      const _ThemeToggleButton(),
      const _ProfileButton(),
    ];
  }
}

/// Vet calendar badge - only rebuilds when VetProvider changes
class _VetCalendarBadge extends StatelessWidget {
  const _VetCalendarBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<VetRecordProvider>(
      builder: (context, vetProvider, _) {
        final locale = Provider.of<LocaleProvider>(context, listen: false).code;
        final t = (String k) => Translations.of(locale, k);
        final todayAppointments = vetProvider.getTodayAppointments();
        final hasAppointmentsToday = todayAppointments.isNotEmpty;

        return IconButton(
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
        );
      },
    );
  }
}

/// Mobile menu button - only reads theme state when popup is built
class _MobileMenuButton extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const _MobileMenuButton({required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

    return PopupMenuButton<String>(
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
            onThemeToggle();
            break;
          case 'profile':
            context.push('/settings');
            break;
        }
      },
      itemBuilder: (BuildContext ctx) {
        // Read providers only when popup is opened (lazy)
        final localeProvider = Provider.of<LocaleProvider>(ctx, listen: false);
        final themeProvider = Provider.of<ThemeProvider>(ctx, listen: false);
        final currentLocale = localeProvider.code;
        final tl = (String k) => Translations.of(currentLocale, k);

        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              tl('language'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.primary,
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
                  themeProvider.isDarkMode ? tl('light_mode') : tl('dark_mode'),
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
                Text(tl('profile')),
              ],
            ),
          ),
        ];
      },
    );
  }
}

/// Language menu button for desktop
class _LanguageMenuButton extends StatelessWidget {
  const _LanguageMenuButton();

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

    return PopupMenuButton<String>(
      tooltip: t('language'),
      icon: const Icon(Icons.language),
      onSelected: (String languageCode) {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(languageCode);
      },
      itemBuilder: (BuildContext ctx) {
        final localeProvider = Provider.of<LocaleProvider>(ctx, listen: false);
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
    );
  }
}

/// Theme toggle button for desktop
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    // Only watches theme for icon state
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

    return IconButton(
      tooltip: themeProvider.isDarkMode ? t('light_mode') : t('dark_mode'),
      icon: Icon(
        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () => themeProvider.toggleTheme(),
    );
  }
}

/// Profile button for desktop
class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final t = (String k) => Translations.of(locale, k);

    return IconButton(
      tooltip: t('profile'),
      icon: const Icon(Icons.account_circle),
      onPressed: () => context.push('/settings'),
    );
  }
}
