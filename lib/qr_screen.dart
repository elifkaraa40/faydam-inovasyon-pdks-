import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processQRCode(String qrContent) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    String message = "";
    Color alertColor = Colors.green;

    final normalizedContent = qrContent.trim().toLowerCase();

    // 1. Durum: El yapımı test girdileri veya simülatör butonları
    if (normalizedContent.contains("faydam_giris_qr") || normalizedContent == "giris") {
      message = "Giriş Onaylandı! Veriler sisteme başarıyla işlendi.";
      alertColor = Colors.green;
    } 
    else if (normalizedContent.contains("faydam_cikis_qr") || normalizedContent == "cikis") {
      message = "Çıkış Onaylandı! Veriler sisteme başarıyla işlendi.";
      alertColor = Colors.orange;
    }
    // 2. Durum: Link içeren gerçek QR kodlar (qrserver.com vb.)
    else if (normalizedContent.contains("qrserver.com") || normalizedContent.contains("http")) {
      // Eğer linkin içinde "register" veya "giriş" anlamına gelen bir kelime geçiyorsa Giriş QR kabul et
      if (normalizedContent.contains("register") || normalizedContent.contains("giris")) {
        message = "Giriş Onaylandı! Veriler sisteme başarıyla işlendi.";
        alertColor = Colors.green;
      } 
      // Geçmiyorsa ya da diğer link tipindeyse Çıkış QR kabul et
      else {
        message = "Çıkış Onaylandı! Veriler sisteme başarıyla işlendi.";
        alertColor = Colors.orange;
      }
    } 
    // 3. Durum: Tamamen alakasız bir QR kod okutulursa
    else {
      message = "Geçersiz QR Kod!\n\nOkunan Değer: \"$qrContent\"\n\nLütfen doğru kodu okutun.";
      alertColor = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: alertColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                alertColor == Colors.red ? Icons.error_outline : Icons.check_circle, 
                color: Colors.white, 
                size: 28
              ),
              const SizedBox(width: 10),
              Text(
                alertColor == Colors.red ? "Hatalı Kod" : "İşlem Başarılı", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isProcessing = false;
                });
              },
              child: const Text("Kapat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final cardBg = settings.isDarkMode ? AppColors.cardNavy : Colors.white;
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("QR Tarama", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Kamera Alanı
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.neonTurquoise, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? rawValue = barcode.rawValue;
                      if (rawValue != null) {
                        _processQRCode(rawValue);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          // Kırmızı/Mavi Lazer Çizgisi Animasyonu
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: _animationController.value * 280,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.neonTurquoise,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonTurquoise.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Bilgilendirme ve Hızlı Test Butonları
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Giriş/Çıkış için QR Kodu Hizalayın",
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _processQRCode("faydam_giris_qr"),
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text("Giriş Test", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _processQRCode("faydam_cikis_qr"),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text("Çıkış Test", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}