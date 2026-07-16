import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const FaydamApp(),
    ),
  );
}

class FaydamApp extends StatelessWidget {
  const FaydamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Faydam PDKS',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}