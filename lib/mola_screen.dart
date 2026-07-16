import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';

class MolaScreen extends StatefulWidget {
  const MolaScreen({super.key});

  @override
  State<MolaScreen> createState() => _MolaScreenState();
}

class _MolaScreenState extends State<MolaScreen> {
  bool _isMolaActive = false;
  Timer? _molaTimer;
  
  int _secondsPassed = 0;       
  int _remainingSeconds = 3600;  
  void _toggleMola() {
    setState(() {
      _isMolaActive = !_isMolaActive;
    });

    if (_isMolaActive) {
      
      _molaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsPassed++;
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          }
        });
      });
    } else {
         _molaTimer?.cancel();
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _molaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final cardBg = settings.isDarkMode ? AppColors.cardNavy : AppColors.lightCard;
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Mola İşlemleri", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text("Mola Geçen", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(_secondsPassed),
                          style: const TextStyle(color: AppColors.neonTurquoise, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text("Kalan Hak", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

           
            const Text("Moladaki Çalışma Arkadaşlarım", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  _buildFriendCard("Ahmet Yılmaz", "10 dakikadır molada", cardBg, textColor),
                  _buildFriendCard("Ayşe Demir", "5 dakikadır molada", cardBg, textColor),
                ],
              ),
            ),

      
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _toggleMola,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _isMolaActive ? Colors.red : AppColors.neonTurquoise, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: settings.isDarkMode ? AppColors.darkNavy : Colors.white,
                ),
                child: Text(
                  _isMolaActive ? "Molayı Bitir" : "Molaya Başla",
                  style: TextStyle(color: _isMolaActive ? Colors.red : AppColors.neonTurquoise, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(String name, String time, Color bg, Color textClr) {
    return Card(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.darkNavy,
          child: Icon(CupertinoIcons.person_fill, color: AppColors.neonTurquoise),
        ),
        title: Text(name, style: TextStyle(color: textClr, fontWeight: FontWeight.bold)),
        subtitle: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}