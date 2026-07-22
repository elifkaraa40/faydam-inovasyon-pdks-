// lib/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  const AppColors._();

  // Arka Plan Renkleri
  static const Color darkNavy = Color(0xFF0D1321);
  static const Color darkNavyBg = Color(0xFF0F1626);
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightBackgroundAlt = Color(0xFFF5F7FA);

  // Kart Renkleri
  static const Color cardNavy = Color(0xFF172033);
  static const Color cardNavyAlt = Color(0xFF1B2236);
  static const Color lightCard = Colors.white;

  // Vurgu ve Marka Renkleri
  static const Color neonTurquoise = Color(0xFF00E5FF);
  static const Color neonCyan = Color(0xFF26BFD0);
  static const Color qrTurquoise = Color(0xFF00A2C2);
  static const Color accentOrange = Color(0xFFFFA726);
}