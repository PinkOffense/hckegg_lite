// lib/app/app_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../state/app_state.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';

import 'auth_gate.dart';

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
        builder: (context, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: Translations.title(localeProvider.code),

            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF7E57C2),
              useMaterial3: true,
              textTheme: GoogleFonts.montserratTextTheme(),
            ),

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
