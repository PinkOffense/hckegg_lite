// lib/app/app_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../state/app_state.dart';
import '../state/theme_provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

import 'auth_gate.dart';
import 'app_theme.dart';
import 'app_router.dart';

class HckEggApp extends StatelessWidget {
  const HckEggApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LocaleProvider('en')),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: Translations.title(localeProvider.code),

            // Enhanced theme with dark mode support
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Proper route configuration
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: '/',

            locale: Locale(localeProvider.code),
            supportedLocales: const [
              Locale('en'),
              Locale('pt'),
              Locale('pt', 'BR'),
            ],

            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
