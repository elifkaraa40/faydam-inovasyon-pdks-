import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'auth_ui.dart';
import 'main_screen.dart';
import 'manager_main_screen.dart';
import 'approval_pending_screen.dart';
import 'register_screen.dart';
import 'services/api_service.dart';
import 'widgets/push_notification_session.dart';

// Existing authenticated screens import these legacy color names from this
// file. Keep the aliases until those screens are migrated to the shared theme.
abstract final class AppColors {
  static const darkNavyBg = Color(0xFF0F1626);
  static const cardNavy = Color(0xFF1B2236);
  static const neonCyan = Color(0xFF26BFD0);
  static const neonTurquoise = Color(0xFF26BFD0);
  static const lightBackground = Color(0xFFF4F7FB);
  static const lightCard = Colors.white;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  bool _validate() {
    final email = _emailController.text.trim();
    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    setState(() {
      _emailError = email.isEmpty
          ? 'E-posta adresinizi girin.'
          : (!validEmail ? 'Geçerli bir e-posta adresi girin.' : null);
      _passwordError =
          _passwordController.text.isEmpty ? 'Parolanızı girin.' : null;
    });
    if (_emailError != null) _emailFocus.requestFocus();
    if (_emailError == null && _passwordError != null) {
      _passwordFocus.requestFocus();
    }
    return _emailError == null && _passwordError == null;
  }

  Future<void> _handleLogin() async {
    if (_isLoading || !_validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final user = Map<String, dynamic>.from(response['user'] as Map);
      context.read<AppSettings>().loginSuccess(
            response['accessToken'].toString(),
            user['id'].toString(),
            user['fullName'].toString(),
            user['email'].toString(),
            user['role']?.toString() ?? 'Personel',
          );
      final deviceNotice = response['deviceSessionNotice']?.toString();
      if (response['previousDeviceSessionRevoked'] == true &&
          deviceNotice != null &&
          deviceNotice.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cihaz oturumu güncellendi'),
            content: Text(deviceNotice),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Devam et'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }
      final isActive = user['accountStatus']?.toString() == 'Active';
      final isManager = user['role']?.toString().toLowerCase() == 'yonetici';
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => !isActive
              ? const PushNotificationSession(child: ApprovalPendingScreen())
              : isManager
                  ? const PushNotificationSession(child: ManagerMainScreen())
                  : const PushNotificationSession(child: MainScreen()),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _passwordError = error.toString());
      _passwordFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Giriş yapılamadı. Bilgilerinizi kontrol edin.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      footer: const Text(
        '© 2026 Faydam İnovasyon',
        textAlign: TextAlign.center,
        style: TextStyle(color: AuthColors.secondary, fontSize: 12),
      ),
      children: [
        const AuthHeading(
          title: 'Sisteme giriş yapın',
          description: 'Hesabınıza erişmek için bilgilerinizi girin.',
        ),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          decoration: authInputDecoration(
            context,
            label: 'E-posta',
            hint: 'ornek@faydam.com',
            errorText: _emailError,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          enabled: !_isLoading,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _handleLogin(),
          decoration: authInputDecoration(
            context,
            label: 'Parola',
            hint: 'Parolanızı girin',
            errorText: _passwordError,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Parolayı göster' : 'Parolayı gizle',
              onPressed: _isLoading
                  ? null
                  : () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AuthColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Giriş yap',
          loading: _isLoading,
          onPressed: _isLoading ? null : _handleLogin,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Hesabınız yok mu?',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE2E8F0)
                      : AuthColors.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
              child: const Text('Kayıt olun.'),
            ),
          ],
        ),
      ],
    );
  }
}
