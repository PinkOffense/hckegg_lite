import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// REQUIRED for localization (fixes Portuguese crash!)
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'l10n/locale_provider.dart';
import 'l10n/translations.dart';

import 'pages/dashboard_page.dart';
import 'pages/egg_list_page.dart';
import 'pages/sync_page.dart';
import 'pages/settings_page.dart';
import 'pages/egg_detail_page.dart';

void main() {
  // Prevent giant error widgets when something fails in build
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 120),
      color: Colors.red.shade200,
      child: SingleChildScrollView(
        child: Text(
          details.exceptionAsString(),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  };

  runApp(const HckEggApp());
}

class HckEggApp extends StatelessWidget {
  const HckEggApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LocaleProvider('en')),
      ],
      child: Consumer<LocaleProvider>(
        builder: (ctx, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: Translations.title(localeProvider.code),

            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF7E57C2),
              useMaterial3: true,
              textTheme: GoogleFonts.montserratTextTheme(),
            ),

            // 🚀 Locale switching works safely now
            locale: Locale(localeProvider.code),

            // 👍 MUST include both EN & PT
            supportedLocales: const [
              Locale('en'),
              Locale('pt'),
              Locale('pt', 'BR'), // optional but recommended
            ],

            // ⭐️ THIS FIXES YOUR CRASH when selecting Portuguese
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // App navigation
            initialRoute: '/',
            routes: {
              '/': (ctx) => const DashboardPage(),
              '/eggs': (ctx) => const EggListPage(),
              '/sync': (ctx) => const SyncPage(),
              '/settings': (ctx) => const SettingsPage(),
            },

            onGenerateRoute: (settings) {
              if (settings.name == '/detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => EggDetailPage(
                    eggId: args['id'] as int,
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
