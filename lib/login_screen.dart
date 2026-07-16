import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ilk_mobil_uygulamam/api_service.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'main_screen.dart';
import 'services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gerçek Cihaz Adını Alıyoruz
      String deviceName = "Android Cihaz";
      if (Platform.isIOS) {
        deviceName = "iOS Cihaz";
      }

      // API Servis üzerinden giriş yapıyoruz
      final result = await _apiService.login(email, password, deviceName);
      final user = Map<String, dynamic>.from(result['user']);

      if (!mounted) return;

      // Kullanıcı bilgilerini AppSettings provider'a aktarıyoruz
      context.read<AppSettings>().loginSuccess(
            result['accessToken'],
            user['id'],
            user['fullName'],
            user['email'],
          );

      // Ana Ekrana geçiş yapıyoruz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
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
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final cardBg = settings.isDarkMode ? AppColors.cardNavy : Colors.white;
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Şirket Logosu
                Image.asset(
                  'assets/faydam_logo.jpg',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: Text(
                        "FAYDAM PDKS",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // E-posta Girişi
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "E-posta Adresi",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: settings.isDarkMode ? AppColors.darkNavy : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Şifre Girişi
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Şifre",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: settings.isDarkMode ? AppColors.darkNavy : Colors.grey[100],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
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
                      onChanged: (val) {
                        setState(() {
                          _rememberMe = val ?? false;
                        });
                      },
                    ),
                    Text("Beni Hatırla", style: TextStyle(color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),

                // Giriş Butonu
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
                            "Sisteme Giriş Yap",
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