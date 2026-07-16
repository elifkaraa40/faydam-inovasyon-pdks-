import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ilk_mobil_uygulamam/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'app_provider.dart';
import 'services/api_service.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({Key? key}) : super(key: key);

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final ApiService _apiService = ApiService();
  final MobileScannerController _scannerController = MobileScannerController();
  final Uuid _uuid = const Uuid();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Tarayıcı kamerasını geçici olarak durduruyoruz
    await _scannerController.stop();

    try {
      // 1. QR Kod Çözümleme ve Validasyon
      final Map<String, dynamic> qrJson = jsonDecode(rawValue);
      final int? version = qrJson['version'];
      final String? eventType = qrJson['eventType'];
      final int? zoneId = qrJson['zoneId'];

      if (version != 1) {
        throw Exception("Desteklenmeyen QR Sürümü.");
      }
      if (eventType != 'Entry' && eventType != 'Exit') {
        throw Exception("Geçersiz geçiş tipi (Yalnızca Entry veya Exit olmalıdır).");
      }
      if (zoneId == null || zoneId <= 0) {
        throw Exception("Geçersiz Bölge Kimliği (Zone ID).");
      }

      // 2. Benzersiz Cihaz Olay Kimliği Üretme (UUID)
      final String deviceEventId = _uuid.v4();

      // 3. API'ye Geçiş Olayını Gönderme
      await _apiService.createAttendanceEvent(
       eventType: eventType ?? 'Entry',
        occurredAt: DateTime.now().toIso8601String(),
        deviceEventId: deviceEventId,
        zoneId: zoneId,
      );

      // 4. Bugünkü Puantaj Durumunu Doğrulama & Güncelleme
      final todayData = await _apiService.getTodayAttendance();
      
      if (!mounted) return;

      // Kullanıcıyı bilgilendirme modalı
      _showSuccessDialog(
        title: eventType == 'Entry' ? "Giriş Başarılı" : "Çıkış Başarılı",
        message: "${qrJson['locationName'] ?? 'Bölge'} alanına geçiş kaydınız oluşturuldu.",
        todayStatus: todayData,
      );

    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
    } finally {
      // İşlem tamamlandıktan sonra tarayıcıyı kontrollü şekilde yeniden açıyoruz
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required Map<String, dynamic> todayStatus,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final settings = Provider.of<AppSettings>(context, listen: false);
        final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: textColor)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: textColor)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                "Bugünkü Durum: ${todayStatus['status'] ?? 'Aktif'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (todayStatus['firstEntry'] != null)
                Text("İlk Giriş: ${todayStatus['firstEntry']}"),
              if (todayStatus['lastExit'] != null)
                Text("Son Çıkış: ${todayStatus['lastExit']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _scannerController.start();
              },
              child: const Text("Tamam", style: TextStyle(color: AppColors.neonTurquoise)),
            )
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final settings = Provider.of<AppSettings>(context, listen: false);
        final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text("Hata", style: TextStyle(color: textColor)),
            ],
          ),
          content: Text(errorMessage, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _scannerController.start();
              },
              child: const Text("Yeniden Dene", style: TextStyle(color: AppColors.neonTurquoise)),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text("Geçiş Kontrol QR", style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // QR çerçeve efekti ve bekleme göstergesi
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neonTurquoise, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.neonTurquoise,
                ),
              ),
            ),
        ],
      ),
    );
  }
}