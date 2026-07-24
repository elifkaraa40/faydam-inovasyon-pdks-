import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart' hide AppColors;
import 'login_screen.dart';
import 'main_screen.dart';
import 'services/api_service.dart';
import 'widgets/push_notification_session.dart';

class ApprovalPendingScreen extends StatefulWidget {
  const ApprovalPendingScreen({super.key});

  @override
  State<ApprovalPendingScreen> createState() => _ApprovalPendingScreenState();
}

class _ApprovalPendingScreenState extends State<ApprovalPendingScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  bool _isChecking = false;
  String _status = 'PendingApproval';
  String _message = 'Kaydınız yönetici onayı bekliyor.';

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final result = await _apiService.getAccountStatus();
      if (!mounted) return;
      final status = result['accountStatus']?.toString() ?? 'PendingApproval';
      setState(() {
        _status = status;
        _message = result['message']?.toString() ?? _message;
      });
      if (status == 'Active' && result['canUseApplication'] == true) {
        _timer?.cancel();
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (!mounted) return;
    context.read<AppSettings>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _continueToApplication() async {
    setState(() => _isChecking = true);
    final refreshed = await _apiService.refreshSession();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (!refreshed) {
      setState(
          () => _message = 'Oturum yenilenemedi. Lütfen tekrar giriş yapın.');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const PushNotificationSession(child: MainScreen()),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rejected = _status == 'Rejected';
    final approved = _status == 'Active';
    return Scaffold(
      backgroundColor: AppColors.darkNavyBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejected
                      ? Icons.cancel_outlined
                      : approved
                          ? Icons.check_circle_outline
                          : Icons.hourglass_top_rounded,
                  color: rejected
                      ? Colors.redAccent
                      : approved
                          ? Colors.greenAccent
                          : AppColors.neonCyan,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  rejected
                      ? 'Kayıt Onaylanmadı'
                      : approved
                          ? 'Hesabınız Onaylandı'
                          : 'Yönetici Onayı Bekleniyor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(_message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 28),
                if (approved)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _continueToApplication,
                      child: const Text('Uygulamaya Devam Et'),
                    ),
                  )
                else if (!rejected)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: const Text('Durumu Kontrol Et'),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: _isChecking ? null : _logout,
                    child: const Text('Çıkış Yap')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
