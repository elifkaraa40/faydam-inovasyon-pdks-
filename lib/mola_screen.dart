import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'app_colors.dart' hide AppColors;

class MolaScreen extends StatefulWidget {
  const MolaScreen({super.key});

  @override
  State<MolaScreen> createState() => _MolaScreenState();
}

class _MolaScreenState extends State<MolaScreen> {
  bool _isBreakActive = false;
  Timer? _breakTimer;
  
  // Saniye cinsinden süre takibi (60 dakika = 3600 saniye)
  int _totalBreakLimit = 3600; 
  int _elapsedSeconds = 0;

  void _toggleBreak() {
    setState(() {
      _isBreakActive = !_isBreakActive;
    });

    if (_isBreakActive) {
      // Saniye saniye sayacı başlat
      _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_elapsedSeconds < _totalBreakLimit) {
          setState(() {
            _elapsedSeconds++;
          });
        } else {
          _stopBreak(); // Süre bittiyse otomatik durdur
        }
      });
    } else {
      _stopBreak();
    }
  }

  void _stopBreak() {
    _breakTimer?.cancel();
    setState(() {
      _isBreakActive = false;
    });
  }

  // Saniyeyi MM:SS formatına çeviren yardımcı fonksiyon
  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isDark = settings.isDarkMode;

    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    int remainingSeconds = _totalBreakLimit - _elapsedSeconds;
    double progressPercent = _elapsedSeconds / _totalBreakLimit;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          "Mola Yönetimi",
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PRO ALAN: Dinamik Sayaç Kartları
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Text("Geçen Mola", style: TextStyle(color: subTextColor, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            _formatDuration(_elapsedSeconds),
                            style: const TextStyle(
                              color: AppColors.neonTurquoise,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Text("Kalan Mola", style: TextStyle(color: subTextColor, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            _formatDuration(remainingSeconds),
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 2. PRO ALAN: Boşluğu Dolduran Görsel Dairesel Grafik Paneli
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: _isBreakActive ? progressPercent : 0.0,
                          strokeWidth: 10,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonTurquoise),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBreakActive ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
                            size: 36,
                            color: _isBreakActive ? AppColors.neonTurquoise : subTextColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isBreakActive ? "Moladasınız" : "Hazır",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _isBreakActive ? "Süre İşliyor" : "Butona Basın",
                            style: TextStyle(color: subTextColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // 3. PRO ALAN: İnteraktif Büyük Buton
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreakActive ? Colors.redAccent : AppColors.neonTurquoise,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  onPressed: _toggleBreak,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBreakActive ? CupertinoIcons.stop_fill : CupertinoIcons.play_fill,
                        color: _isBreakActive ? Colors.white : AppColors.darkNavy,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isBreakActive ? "Molayı Bitir" : "Molayı Başlat",
                        style: TextStyle(
                          color: _isBreakActive ? Colors.white : AppColors.darkNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // 4. PRO ALAN: Moladaki Arkadaşlar ve Günlük Geçmiş
              Text(
                "Moladaki Arkadaşlarım",
                style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.darkNavy,
                      child: Icon(CupertinoIcons.person, size: 16, color: AppColors.neonTurquoise),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ahmet Yılmaz", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        Text("10 dakikadır molada", style: TextStyle(color: subTextColor, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}