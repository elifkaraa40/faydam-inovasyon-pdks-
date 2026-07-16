import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'login_screen.dart';
import 'services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Sunucu oturumu kapatılır. ApiService aynı zamanda
      // cihazdaki access ve refresh tokenları temizler.
      await _apiService.logout();
    } catch (_) {
      // Sunucuya ulaşılamasa bile cihazdaki oturum
      // ApiService tarafından temizlenir.
    }

    if (!mounted) return;

    context.read<AppSettings>().logout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    final cardBg =
        settings.isDarkMode ? AppColors.cardNavy : AppColors.lightCard;

    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    final userName = settings.userName?.trim().isNotEmpty == true
        ? settings.userName!
        : 'Kullanıcı';

    final userEmail = settings.userEmail?.trim().isNotEmpty == true
        ? settings.userEmail!
        : 'E-posta bilgisi bulunamadı';

    return Scaffold(
      backgroundColor:
          settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Profilim',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: settings.isDarkMode
            ? AppColors.darkNavy
            : AppColors.lightBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profil kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.darkNavy,
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: AppColors.neonTurquoise,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tema seçimi
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                value: settings.isDarkMode,
                onChanged: _isLoggingOut
                    ? null
                    : (_) {
                        settings.toggleTheme();
                      },
                activeThumbColor: AppColors.neonTurquoise,
                title: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.moon_fill,
                      color: AppColors.neonTurquoise,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Koyu Tema',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dil seçimi
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.globe,
                          color: AppColors.neonTurquoise,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Uygulama Dili',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: settings.language,
                    dropdownColor: cardBg,
                    underline: const SizedBox(),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Türkçe (TR)',
                        child: Text('Türkçe (TR)'),
                      ),
                      DropdownMenuItem(
                        value: 'English (EN)',
                        child: Text('English (EN)'),
                      ),
                    ],
                    onChanged: _isLoggingOut
                        ? null
                        : (value) {
                            if (value != null) {
                              settings.setLanguage(
                                value,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Çıkış butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoggingOut ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(
                    alpha: 0.1,
                  ),
                  disabledBackgroundColor: Colors.red.withValues(
                    alpha: 0.05,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
