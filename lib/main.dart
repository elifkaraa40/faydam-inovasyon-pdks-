import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final ApiService _apiService = ApiService();

  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final hasSession = await _apiService.hasSession();

      if (!hasSession) {
        _showLogin();
        return;
      }

      final accessToken = await _apiService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        await _apiService.clearSession();
        _showLogin();
        return;
      }

      final profile = await _apiService.getUserProfile();

      final userId = profile['id']?.toString() ?? '';

      final fullName = profile['fullName']?.toString() ?? '';

      final email = profile['email']?.toString() ?? '';

      if (userId.isEmpty || fullName.isEmpty || email.isEmpty) {
        await _apiService.clearSession();
        _showLogin();
        return;
      }

      if (!mounted) return;

      context.read<AppSettings>().restoreSession(
            accessToken: accessToken,
            userId: userId,
            userName: fullName,
            email: email,
          );

      setState(() {
        _destination = const MainScreen();
      });
    } catch (_) {
      await _apiService.clearSession();
      _showLogin();
    }
  }

  void _showLogin() {
    if (!mounted) return;

    setState(() {
      _destination = const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;

    if (destination != null) {
      return destination;
    }

    return const Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.neonTurquoise,
        ),
      ),
    );
  }
}
