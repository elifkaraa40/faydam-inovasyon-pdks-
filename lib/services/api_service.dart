import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  // Eğer gerçek bir backend URL'iniz varsa buraya yazabilirsiniz
  final String baseUrl = "https://api.faydam.com/v1"; 

  /// QR Kod okutulduğunda tetiklenen ve sunucuya veri gönderen metod
  Future<Map<String, dynamic>> scanAttendanceQr({
    required String qrValue,
    required String occurredAt,
    required String deviceEventId,
  }) async {
    try {
      // TODO: Gerçek API entegrasyonu yapacağınız zaman burayı HTTP isteğine çevirin.
      // Örnek: final response = await http.post(Uri.parse('$baseUrl/attendance/scan'), body: {...});
      
      // Simülasyon için 1 saniye gecikme ekliyoruz (ağı taklit etmek için)
      await Future.delayed(const Duration(seconds: 1));

      // QR içeriğine göre giriş mi çıkış mı olduğuna sunucu karar veriyor simülasyonu:
      // Eğer QR kodu içinde 'exit' kelimesi geçiyorsa veya rastgele durumlar için:
      final bool isExitScenario = qrValue.toLowerCase().contains('exit') || DateTime.now().second % 2 == 0;

      debugPrint("API'ye Gönderilen QR: $qrValue");
      debugPrint("Event ID: $deviceEventId");

      // QrScreen'in beklediği haritayı (Map) başarıyla dönüyoruz:
      return {
        'eventType': isExitScenario ? 'exit' : 'entry',
        'workplaceName': 'Faydam Teknoloji A.Ş.',
        'zoneName': 'Ana Kapı Turnikesi',
        'occurredAt': occurredAt,
      };
    } catch (e) {
      // Bir hata oluşursa QrScreen'deki catch bloğuna fırlatılır
      throw Exception("Geçiş kaydı gönderilirken hata oluştu: ${e.toString()}");
    }
  }

  /// Kullanıcının bugünkü giriş çıkış durum özetini getiren metod
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      // Simülasyon gecikmesi
      await Future.delayed(const Duration(milliseconds: 500));

      // QrScreen'in beklediği bugünkü durum verileri:
      return {
        'status': 'Mesaide',
        'firstEntry': '08:45',
        'lastExit': DateTime.now().second % 2 == 0 ? '17:30' : '',
      };
    } catch (e) {
      throw Exception("Bugünkü durum bilgisi alınamadı.");
    }
  }

  Future<void> createLeaveRequest({required String leaveType, required String startDate, required String endDate, required String reason, required String dayPortion}) async {}

  Future<void> deleteLeaveRequest(Object requestId) async {}

  Future<Object?> getLeaveRequests() async {}

  Future<Object?> getUserProfile() async {}

  Future<void> clearSession() async {}

  Future<Object?> getAccessToken() async {}

  Future<Object?> hasSession() async {}

  Future<void> logout() async {}
}