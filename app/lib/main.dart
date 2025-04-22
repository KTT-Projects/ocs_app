import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocs_app/pages/main_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  // Ensure that Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localizations
  await Future.wait([
    initializeDateFormatting('en'),
    initializeDateFormatting('ja'),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    const appTitle = 'Osakikamijima Community Site';
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,

      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF04143A),
          primary: const Color(0xFF04143A),
          background: const Color(0xFFF1F6F8),
          secondary: const Color(0xFFA2BFF6),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        textTheme: GoogleFonts.mPlus1pTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF04143A),
          brightness: Brightness.dark,
          primary: const Color(0xFF04143A),
          background: const Color(0xFF121212),
          secondary: const Color(0xFFA2BFF6),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
      ),
      home: const MainPage(),
    );
  }
}
