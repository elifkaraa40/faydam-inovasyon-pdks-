import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'session_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider üzerinden mevcut tema ayarlarını dinliyoruz
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      title: 'İlk Mobil Uygulamam',
      debugShowCheckedModeBanner: false,
      locale: settings.isEnglish ? const Locale('en') : const Locale('tr'),
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Karanlık ve Aydınlık Tema Ayarları
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Arial',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0F1626),
      ),

      home: const SessionGate(),
    );
  }
}
