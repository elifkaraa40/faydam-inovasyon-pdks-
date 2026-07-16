// TODO Implement this library.import 'import';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Arkadaşının backend'i bilgisayarında çalıştırırken yerel ağda erişebilmen için şimdilik geçici bir URL.
  // Gerçek sunucuya geçildiğinde burası "https://api.sirketiniz.com" gibi bir adres olacak.
  static const String baseUrl = "http://10.0.2.2:8000/api"; // 10.0.2.2, Android emülatörün bilgisayarını görmesini sağlar.

  // 1. GİRİŞ YAPMA FONKSİYONU (LOGIN)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Giriş başarılıysa sunucudan dönen veriyi (Token, Kullanıcı Bilgileri vb.) çözüyoruz
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Giriş Hatası: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("İnternet/Bağlantı Hatası: $e");
      return null;
    }
  }

  // 2. PROFİL BİLGİLERİNİ GETİRME FONKSİYONU
  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Güvenli geçiş için token gönderiyoruz
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print("Profil getirme hatası: $e");
      return null;
    }
  }
}