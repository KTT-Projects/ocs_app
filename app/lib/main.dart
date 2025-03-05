import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ocs_app/pages/main_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  // Ensure that Flutter is initialized before calling Firebase.initializeApp()
  WidgetsFlutterBinding.ensureInitialized();

  // runApp(const MyApp());
  initializeDateFormatting('ja').then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: '大崎上島コミュニティーサイト',
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
      locale: const Locale('ja'), // Set Japanese as default

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
