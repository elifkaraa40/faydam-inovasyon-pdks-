import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'app_colors.dart' hide AppColors; // 1. Adımda oluşturduğumuz merkezi renk sınıfı

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = "";
  String _currentDate = "";
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Profesyonel Timer: Her saniye saati ve tarihi tetikler, hafıza dostudur.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    
    // Paket bağımlılığı olmadan çalışan yerel Türkçe tarih dönüştürücü
    final gunler = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    final aylar = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
    
    setState(() {
      // Saati sıfır dolgulu yapar (Örn: 11:19:33)
      _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      
      // Tarih formatı: Çarşamba, 22 Temmuz 2026
      _currentDate = "${gunler[now.weekday - 1]}, ${now.day} ${aylar[now.month - 1]} ${now.year}";
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel(); // Sayfa bellekten atılırken timer durdurulur.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isDark = settings.isDarkMode;
    
    // Premium Tasarım Renk Yönetimi
    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    // Mock/Yerel Güvenli Veriler
    final userName = settings.userName ?? "Ahmet Yılmaz"; 
    const String bugunkuGirisSaati = "08:30";
    const String fazlaMesai = "2 Saat 15 Dk";
    const String eksikMesai = "45 Dakika";
    const double gunlukIlerleme = 0.72; // %72 tamamlandı

    final List<Map<String, String>> haftalikTablo = [
      {"gun": "Pazartesi", "giris": "08:25", "cikis": "18:05"},
      {"gun": "Salı", "giris": "08:45", "cikis": "18:00"},
      {"gun": "Çarşamba", "giris": "08:30", "cikis": "--:--"},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PRO ALAN: Kullanıcı Karşılama Paneli (Header)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hoş Geldin,",
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neonTurquoise, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.cardNavy,
                      child: Icon(CupertinoIcons.person_fill, color: AppColors.neonTurquoise),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. PRO ALAN: Gelişmiş Canlı Saat Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _currentDate.toUpperCase(),
                      style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        color: AppColors.neonTurquoise,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // 3. PRO ALAN: Günlük Çalışma İlerleme Barı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Günlük İlerleme", style: TextStyle(color: subTextColor, fontSize: 12)),
                        Text("%${(gunlukIlerleme * 100).toInt()}", style: const TextStyle(color: AppColors.neonTurquoise, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: gunlukIlerleme,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        color: AppColors.neonTurquoise,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. PRO ALAN: Genel Durum Özet Paneli (Mola & İzin)
              Text(
                "Genel Bakış",
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.time, color: AppColors.accentOrange, size: 22),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Bugünkü Mola", style: TextStyle(color: subTextColor, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text("25 / 60 Dk", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.airplane, color: Colors.purpleAccent, size: 22),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Kalan İzniniz", style: TextStyle(color: subTextColor, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text("14 Gün", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.arrow_right_to_line_alt, color: AppColors.neonTurquoise, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "Bugünkü Giriş Saati",
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      bugunkuGirisSaati,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Haftalık Tablo
              Text(
                "Haftalık Tablo",
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("Gün", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(child: Text("Giriş", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(child: Text("Çıkış", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                    ),
                    Divider(color: borderColor, height: 24),
                    ...haftalikTablo.map((veri) {
                      final isLate = (veri["giris"] == "08:45");
                      final isOvertime = (veri["cikis"] == "18:05");
                      final isCurrentDay = (veri["cikis"] == "--:--");

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                veri["gun"] ?? "",
                                style: TextStyle(color: textColor, fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                veri["giris"] ?? "",
                                style: TextStyle(
                                  color: isLate ? Colors.redAccent : textColor,
                                  fontWeight: isLate || isCurrentDay ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                veri["cikis"] ?? "",
                                style: TextStyle(
                                  color: isOvertime ? AppColors.accentOrange : (isCurrentDay ? AppColors.neonTurquoise : textColor),
                                  fontWeight: isOvertime || isCurrentDay ? FontWeight.bold : FontWeight.normal,
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Fazla Mesai", style: TextStyle(color: subTextColor, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            fazlaMesai,
                            style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold, fontSize: 14),
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Eksik Mesai", style: TextStyle(color: subTextColor, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            eksikMesai,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
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
      ),
    );
  }
}