import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'attendance_screen.dart';
import 'employee_actions_screen.dart';
import 'home_screen.dart';
import 'qr_screen.dart'; // Importumuz burada temizce dursun
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final HomeScreenController _homeController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _homeController = HomeScreenController();
    _screens = [
      HomeScreen(controller: _homeController),
      const AttendanceScreen(),
      QrScreen(onAttendanceChanged: _homeController.refresh),
      const EmployeeActionsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

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
          if (index == 0) {
            _homeController.refresh();
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.time), label: 'Puantaj'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.qrcode_viewfinder), label: 'QR Kod'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_grid_2x2), label: 'İşlemler'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person), label: 'Profilim'),
        ],
      ),
    );
  }
}
