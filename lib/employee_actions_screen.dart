import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'izin_screen.dart';
import 'mola_screen.dart';
import 'work_location_screen.dart';
import 'attendance_correction_screen.dart';

class EmployeeActionsScreen extends StatelessWidget {
  const EmployeeActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    final text = dark ? Colors.white : AppColors.darkNavy;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('İşlemler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            title: 'Mola',
            description:
                'Molanızı başlatın, bitirin ve geçmişinizi görüntüleyin.',
            icon: Icons.free_breakfast_outlined,
            textColor: text,
            dark: dark,
            onTap: () => _open(context, const MolaScreen()),
          ),
          _ActionCard(
            title: 'İzin Talepleri',
            description: 'İzin talebi oluşturun ve durumunu takip edin.',
            icon: Icons.event_available_outlined,
            textColor: text,
            dark: dark,
            onTap: () => _open(context, const IzinScreen()),
          ),
          _ActionCard(
            title: 'Çalışma Konumu',
            description: 'Saha görevi veya uzaktan çalışma talebi oluşturun.',
            icon: Icons.location_on_outlined,
            textColor: text,
            dark: dark,
            onTap: () => _open(context, const WorkLocationScreen()),
          ),
          _ActionCard(
            title: 'Puantaj Düzeltme Talebi',
            description: 'Eksik veya hatalı giriş-çıkış kaydı için talep oluşturun.',
            icon: Icons.edit_calendar_outlined,
            textColor: text,
            dark: dark,
            onTap: () => _open(context, const AttendanceCorrectionScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.textColor,
    required this.dark,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color textColor;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: dark ? AppColors.cardNavy : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.neonTurquoise.withValues(alpha: .15),
          child: Icon(icon, color: AppColors.neonTurquoise),
        ),
        title: Text(title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description,
              style: TextStyle(color: textColor.withValues(alpha: .7))),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
