import 'package:flutter/material.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'router.dart';

class CungHatApp extends StatelessWidget {
  const CungHatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cùng Hát',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4), useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      routerConfig: appRouter,
    );
  }
}
