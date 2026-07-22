import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'approval_pending_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'manager_main_screen.dart';
import 'services/api_service.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final ApiService _apiService = ApiService();
  late Future<Widget> _destination = _resolveDestination();

  Future<Widget> _resolveDestination() async {
    final token = await _apiService.getAccessToken();
    final user = await _apiService.getStoredUser();
    if (token == null || user == null) return const LoginScreen();

    if (mounted) {
      context.read<AppSettings>().restoreSession(
            accessToken: token,
            userId: user['id']?.toString() ?? '',
            userName: user['fullName']?.toString() ?? '',
            email: user['email']?.toString() ?? '',
            role: user['role']?.toString() ?? 'Personel',
          );
    }

    final status = await _apiService.getAccountStatus();
    if (status['accountStatus'] == 'Active' &&
        status['canUseApplication'] == true) {
      await _apiService.refreshSession();
      final isManager = user['role']?.toString().toLowerCase() == 'yonetici';
      return isManager ? const ManagerMainScreen() : const MainScreen();
    }
    return const ApprovalPendingScreen();
  }

  void _retry() {
    setState(() => _destination = _resolveDestination());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 56),
                    const SizedBox(height: 16),
                    const Text('Sunucuya ulaşılamadı.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
