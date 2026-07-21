import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'approval_pending_screen.dart';
import 'auth_ui.dart';
import 'services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _fullNameError;
  String? _emailError;
  String? _passwordError;

  bool _validate() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _fullNameError = fullName.isEmpty ? 'Ad soyad alanını doldurun.' : null;
      _emailError = email.isEmpty ? 'E-posta adresinizi girin.' : null;
      _passwordError = password.isEmpty
          ? 'Parolanızı girin.'
          : (password.length < 8 || password.length > 72
              ? 'Parola en az 8, en fazla 72 karakter olmalıdır.'
              : null);
    });
    return _fullNameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _handleRegister() async {
    if (_isLoading || !_validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.register(
        fullName: _fullNameController.text.trim(),
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
          );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ApprovalPendingScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $error'),
          backgroundColor: AuthColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE2E8F0)
        : AuthColors.navy;
    return AuthShell(
      logoWidth: 220,
      children: [
        const AuthHeading(
          title: 'Hesabınızı oluşturun',
          description: 'Faydam PDKS’ye erişmek için bilgilerinizi eksiksiz girin.',
        ),
        TextField(
          controller: _fullNameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) {
            if (_fullNameError != null) setState(() => _fullNameError = null);
          },
          decoration: authInputDecoration(
            context,
            label: 'Ad Soyad',
            hint: 'Adınızı ve soyadınızı girin',
            errorText: _fullNameError,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
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
          enabled: !_isLoading,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _handleRegister(),
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
        const SizedBox(height: 8),
        const Text(
          'Parola 8–72 karakter uzunluğunda olmalıdır.',
          style: TextStyle(color: AuthColors.secondary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Kayıt ol',
          loading: _isLoading,
          onPressed: _isLoading ? null : _handleRegister,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text('Zaten hesabınız var mı?', style: TextStyle(color: bodyColor)),
            ),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Giriş yapın.'),
            ),
          ],
        ),
      ],
    );
  }
}
