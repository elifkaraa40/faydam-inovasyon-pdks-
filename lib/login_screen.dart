import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'main_screen.dart'; // Yönlendirme yapacağımız ana ekran

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

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

    // API bağlantısı olmadığı için yapay bir gecikme simülasyonu yapıyoruz (1 saniye)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // GEÇİCİ API YÖNLENDİRME MANTIĞI:
    // Eğer girilen bilgiler bizim test hesaplarımızdan biriyse doğrudan içeri alıyoruz!
    if (email == "yonetici2@faydam.com" && password == "12345678") {
      // Başarılı giriş: Kullanıcıyı MainScreen'e yönlendiriyoruz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Eğer bilgiler uyuşmuyorsa bir uyarı gösteriyoruz (veya test kolaylığı için bunu da içeri alabilirsin)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("E-posta veya şifre hatalı! (Test için: yonetici2@faydam.com / 12345678)"),
          backgroundColor: Colors.red,
        ),
      );
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
                ),
                const SizedBox(height: 32),

                // E-posta Girişi
                TextField(
                  controller: _emailController,
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
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Şifre",
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

                // Giriş Butonu (Dönme efekti veya Giriş Yap yazısı)
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