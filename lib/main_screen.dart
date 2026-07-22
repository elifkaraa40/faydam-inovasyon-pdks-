import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_provider.dart';
import 'home_screen.dart';
import 'mola_screen.dart';
import 'qr_screen.dart'; // Importumuz burada temizce dursun
import 'izin_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Başlarındaki 'const' kelimelerini kaldırdık, hata vermesini engelledik!
  final List<Widget> _screens = [
    const HomeScreen(),
    const MolaScreen(),
    QrScreen(), // Kırmızı çizgi çeken yer artık özgür
    const IzinScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Sekmelerin kaymasını engeller
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'Mola'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.qrcode_viewfinder), label: 'QR Kod'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.calendar), label: 'İzin'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profilim'),
        ],
      ),
    );
  }
}