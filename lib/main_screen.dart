import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_provider.dart';
import 'home_screen.dart';
import 'mola_screen.dart';
import 'qr_screen.dart';
import 'izin_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  
  final List<Widget> _screens = [
    const HomeScreen(),
    const MolaScreen(),
    const QRScanScreen(),
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkNavy,
        selectedItemColor: AppColors.neonTurquoise,
        unselectedItemColor: Colors.white30,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.drop), label: "Mola"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.qrcode_viewfinder), label: "QR Kod"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.calendar), label: "İzin"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: "Profilim"),
        ],
      ),
    );
  }
}