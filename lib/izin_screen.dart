import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';

class IzinScreen extends StatelessWidget {
  const IzinScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final cardBg = settings.isDarkMode ? AppColors.cardNavy : Colors.white;
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    // Çökmeyi önlemek için güvenli mock (yapay) veriler
    final List<Map<String, String>> izinlerim = [
      {"tur": "Yıllık İzin", "baslangic": "12.06.2026", "durum": "Onaylandı"},
      {"tur": "Mazeret İzni", "baslangic": "02.07.2026", "durum": "Beklemede"},
    ];

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("İzinlerim", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: izinlerim.map((izin) {
          final isApproved = izin["durum"] == "Onaylandı";
          return Card(
            color: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(izin["tur"] ?? "", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              subtitle: Text("Başlangıç: ${izin["baslangic"]}", style: const TextStyle(color: Colors.grey)),
              trailing: Chip(
                backgroundColor: isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                label: Text(
                  izin["durum"] ?? "",
                  style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}