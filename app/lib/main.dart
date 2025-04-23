import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_client.dart';
import 'providers/language_provider.dart';
import 'package:ocs_app/pages/main_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient();
  
  await Future.wait([
    apiClient.initialize(),
    initializeDateFormatting('en'),
    initializeDateFormatting('ja'),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(prefs),
        ),
      ],
      child: MyApp(apiClient: apiClient),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  
  const MyApp({
    super.key,
    required this.apiClient,
  });
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    const appTitle = 'Osakikamijima Community Site';
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
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
      locale: languageProvider.locale,
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
      home: MainPage(apiClient: apiClient),
        );
      },
    );
  }
}
