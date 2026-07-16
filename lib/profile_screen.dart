
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final cardBg = settings.isDarkMode ? AppColors.cardNavy : AppColors.lightCard;
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
          
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.darkNavy,
                    child: Icon(CupertinoIcons.person_fill, color: AppColors.neonTurquoise, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.userName ?? "Yönetici Hesabı", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(settings.userEmail ?? "yonetici2@faydam.com", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                value: settings.isDarkMode,
                onChanged: (_) => settings.toggleTheme(),
                activeThumbColor: AppColors.neonTurquoise,
                title: Row(
                  children: [
                    const Icon(CupertinoIcons.moon_fill, color: AppColors.neonTurquoise),
                    const SizedBox(width: 12),
                    Text("Koyu Tema", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.globe, color: AppColors.neonTurquoise),
                      const SizedBox(width: 12),
                      Text("Uygulama Dili", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  DropdownButton<String>(
                    value: settings.language,
                    dropdownColor: cardBg,
                    underline: const SizedBox(),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: "Türkçe (TR)", child: Text("Türkçe (TR)")),
                      DropdownMenuItem(value: "English (EN)", child: Text("English (EN)")),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setLanguage(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  settings.logout();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
              
                  backgroundColor: Colors.red.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}