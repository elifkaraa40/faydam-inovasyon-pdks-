import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color darkNavy = Color(0xFF0D1321);

  static const Color cardNavy = Color(0xFF172033);

  static const Color neonTurquoise = Color(0xFF00E5FF);

  static const Color accentOrange = Color(0xFFFFA726);

  static const Color lightBackground = Color(0xFFF3F4F6);

  static const Color lightCard = Colors.white;
}

class AppSettings extends ChangeNotifier {
  bool _isDarkMode = true;

  String _language = 'Türkçe (TR)';

  String? _accessToken;
  String? _userId;
  String? _userName;
  String? _userEmail;

  bool get isDarkMode => _isDarkMode;

  String get language => _language;

  /// Yeni kodlarda kullanılacak token getter'ı.
  String? get accessToken => _accessToken;

  /// Eski ekranların bozulmaması için korunmuştur.
  String? get token => _accessToken;

  String? get userId => _userId;

  String? get userName => _userName;

  String? get userEmail => _userEmail;

  bool get isLoggedIn {
    return _accessToken != null &&
        _accessToken!.isNotEmpty &&
        _userId != null &&
        _userId!.isNotEmpty;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String language) {
    if (language != 'Türkçe (TR)' && language != 'English (EN)') {
      return;
    }

    if (_language == language) return;

    _language = language;
    notifyListeners();
  }

  void loginSuccess(
    String accessToken,
    String userId,
    String userName,
    String email,
  ) {
    _accessToken = accessToken;
    _userId = userId;
    _userName = userName;
    _userEmail = email;

    notifyListeners();
  }

  /// Uygulama yeniden açıldığında güvenli depodan alınan
  /// kullanıcı bilgilerinin Provider'a aktarılması için
  /// kullanılabilir.
  void restoreSession({
    required String accessToken,
    required String userId,
    required String userName,
    required String email,
  }) {
    _accessToken = accessToken;
    _userId = userId;
    _userName = userName;
    _userEmail = email;

    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _userId = null;
    _userName = null;
    _userEmail = null;

    notifyListeners();
  }
}
