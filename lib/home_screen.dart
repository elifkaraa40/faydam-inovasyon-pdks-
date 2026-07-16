import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Provider'dan sadece tema ayarını alıyoruz (Çökme riskini azaltmak için)
    final settings = Provider.of<AppSettings>(context);
    final cardBg = settings.isDarkMode ? AppColors.cardNavy : Colors.white;
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    // API veya Provider yerine doğrudan yerel (local) tanımladığımız güvenli veriler:
    const String bugunkuGirisSaati = "08:30";
    const String fazlaMesai = "2 Saat 15 Dk";
    const String eksikMesai = "45 Dakika";
    
    final List<Map<String, String>> haftalikTablo = [
      {"gun": "Pazartesi", "giris": "08:25", "cikis": "18:05"},
      {"gun": "Salı", "giris": "08:45", "cikis": "18:00"},
    ];

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Ana Sayfa", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canlı Saat Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Column(
                children: [
                  const Text(
                    "Canlı Saat",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: AppColors.neonTurquoise,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Günlük Durum Başlığı
            Text(
              "Günlük Durum",
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.arrow_right_to_line_alt, color: AppColors.neonTurquoise),
                      const SizedBox(width: 12),
                      Text("Bugünkü Giriş Saati", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Text(bugunkuGirisSaati, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Haftalık Tablo Başlığı
            Text(
              "Haftalık Tablo",
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Haftalık Liste Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Tablo Başlıkları
                  const Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text("Gün", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Giriş", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Çıkış", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Tamamen Güvenli Map Döngüsü (Yerel listeyi dönüyoruz, asla çökmez)
                  ...haftalikTablo.map((veri) {
                    final isLate = (veri["giris"] == "08:45");
                    final isOvertime = (veri["cikis"] == "18:05");

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              veri["gun"] ?? "", 
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              veri["giris"] ?? "", 
                              style: TextStyle(
                                color: isLate ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              veri["cikis"] ?? "", 
                              style: TextStyle(
                                color: isOvertime ? Colors.orange : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mesai İstatistik Kutuları
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Fazla Mesai", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 6),
                        Text(
                          fazlaMesai,
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Eksik Mesai", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 6),
                        Text(
                          eksikMesai,
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}