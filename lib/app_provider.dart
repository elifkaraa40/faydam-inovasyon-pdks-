import 'package:flutter/material.dart';

class AppColors {
  static const Color darkNavy = Color(0xFF0D1321);      
  static const Color cardNavy = Color(0xFF172033);      
  static const Color neonTurquoise = Color(0xFF00E5FF); 
  static const Color accentOrange = Color(0xFFFFA726);  
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightCard = Colors.white;
}

class AppSettings extends ChangeNotifier {
  bool _isDarkMode = true;
  String _language = "Türkçe (TR)";
  String? _token;
  String? _userId;
  String? _userName = "Yönetici Hesabı";
  String? _userEmail = "yonetici2@faydam.com";

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void loginSuccess(String token, String userId, String userName, String email) {
    _token = token;
    _userId = userId;
    _userName = userName;
    _userEmail = email;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _userId = null;
    _userName = "Yönetici Hesabı";
    _userEmail = "yonetici2@faydam.com";
    notifyListeners();
  }
}