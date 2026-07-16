import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'main_screen.dart';
import 'services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();

    // Parolaya trim uygulanmaz. Kullanıcının girdiği değer
    // değiştirilmeden API'ye gönderilir.
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen e-posta ve parola alanlarını doldurun.',
          ),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Parola en az 6 karakter olmalıdır.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String deviceName = 'Android Cihaz';

      if (Platform.isIOS) {
        deviceName = 'iOS Cihaz';
      }

      final result = await _apiService.login(
        email,
        password,
        deviceName,
      );

      final userData = result['user'];

      if (userData is! Map) {
        throw Exception(
          'Sunucudan geçerli kullanıcı bilgisi alınamadı.',
        );
      }

      final user = Map<String, dynamic>.from(userData);

      final accessToken = result['accessToken']?.toString() ?? '';

      final userId = user['id']?.toString() ?? '';

      final fullName = user['fullName']?.toString() ?? '';

      final userEmail = user['email']?.toString() ?? '';

      if (accessToken.isEmpty ||
          userId.isEmpty ||
          fullName.isEmpty ||
          userEmail.isEmpty) {
        throw Exception(
          'Giriş cevabındaki kullanıcı bilgileri eksik.',
        );
      }

      if (!mounted) return;

      context.read<AppSettings>().loginSuccess(
            accessToken,
            userId,
            fullName,
            userEmail,
          );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    final cardBg = settings.isDarkMode ? AppColors.cardNavy : Colors.white;

    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor:
          settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Şirket logosu
                Image.asset(
                  'assets/faydam_logo.jpg',
                  height: 100,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: Text(
                        'FAYDAM PDKS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // E-posta alanı
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'E-posta Adresi',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: settings.isDarkMode
                        ? AppColors.darkNavy
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Parola alanı
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                  enableSuggestions: false,
                  autocorrect: false,
                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _handleLogin();
                    }
                  },
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Şifre',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: settings.isDarkMode
                        ? AppColors.darkNavy
                        : Colors.grey[100],
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Parolayı göster'
                          : 'Parolayı gizle',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Beni Hatırla
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.neonTurquoise,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                    ),
                    Text(
                      'Beni Hatırla',
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.neonTurquoise,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sisteme Giriş Yap',
                            style: TextStyle(
                              color: AppColors.neonTurquoise,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
