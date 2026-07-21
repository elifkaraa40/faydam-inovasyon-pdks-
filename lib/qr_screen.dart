import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'app_provider.dart';
import 'services/api_service.dart';

// Projede eksik olabilecek renk tanımlamalarını garantiye alıyoruz
class AppColors {
  static const Color darkNavy = Color(0xFF0F1626);
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color neonTurquoise = Color(0xFF00A2C2);
}

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final ApiService _apiService = ApiService();

  // Paket içerisindeki gerçek MobileScannerController artık sorunsuz çalışacak
  final MobileScannerController _scannerController = MobileScannerController();

  final Uuid _uuid = const Uuid();

  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await _scannerController.stop();

    try {
      // QR okuyucudan alınan ham değer değiştirilmeden API'ye gönderilir.
      final result = await _apiService.scanAttendanceQr(
        qrValue: rawValue,
        occurredAt: DateTime.now().toIso8601String(),
        deviceEventId: _uuid.v4(),
      );

      if (!mounted) return;

      final eventType = result['eventType']?.toString() ?? '';
      final workplaceName = result['workplaceName']?.toString() ?? 'İşyeri';
      final zoneName = result['zoneName']?.toString() ?? 'Geçiş Bölgesi';
      final occurredAt = result['occurredAt']?.toString();

      final isEntry = eventType.toLowerCase() == 'entry';
      final isExit = eventType.toLowerCase() == 'exit';

      if (!isEntry && !isExit) {
        throw Exception('Sunucudan geçersiz geçiş tipi alındı.');
      }

      Map<String, dynamic> todayData = <String, dynamic>{};

      try {
        todayData = await _apiService.getTodayAttendance();
      } catch (_) {
        todayData = <String, dynamic>{};
      }

      if (!mounted) return;

      await _showSuccessDialog(
        title: isEntry ? 'Giriş Başarılı' : 'Çıkış Başarılı',
        message: _createSuccessMessage(
          workplaceName: workplaceName,
          zoneName: zoneName,
          occurredAt: occurredAt,
        ),
        todayStatus: todayData,
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');
      await _showErrorDialog(message);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        await _scannerController.start();
      }
    }
  }

  String _createSuccessMessage({
    required String workplaceName,
    required String zoneName,
    required String? occurredAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('$workplaceName - $zoneName')
      ..write('alanındaki geçiş kaydınız oluşturuldu.');

    if (occurredAt != null && occurredAt.isNotEmpty) {
      final parsedDate = DateTime.tryParse(occurredAt);

      if (parsedDate != null) {
        final localDate = parsedDate.toLocal();
        final hour = localDate.hour.toString().padLeft(2, '0');
        final minute = localDate.minute.toString().padLeft(2, '0');

        buffer
          ..writeln()
          ..write('İşlem saati: $hour:$minute');
      }
    }

    return buffer.toString();
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required Map<String, dynamic> todayStatus,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final settings = Provider.of<AppSettings>(
          dialogContext,
          listen: false,
        );

        final textColor =
            settings.isDarkMode ? Colors.white : AppColors.darkNavy;

        final status = todayStatus['status']?.toString();
        final firstEntry = todayStatus['firstEntry']?.toString();
        final lastExit = todayStatus['lastExit']?.toString();

        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(color: textColor),
              ),
              if (todayStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Bugünkü Durum: ${status ?? 'Aktif'}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (firstEntry != null && firstEntry.isNotEmpty)
                  Text(
                    'İlk Giriş: $firstEntry',
                    style: TextStyle(color: textColor),
                  ),
                if (lastExit != null && lastExit.isNotEmpty)
                  Text(
                    'Son Çıkış: $lastExit',
                    style: TextStyle(color: textColor),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Tamam',
                style: TextStyle(color: AppColors.neonTurquoise),
              ),
            ),
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
      backgroundColor:
          settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Geçiş Kontrol QR',
          style: TextStyle(color: textColor),
        ),
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
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.neonTurquoise,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withAlpha(
                  128), // .withValues yerine geriye dönük uyumlu kullanım
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

  Future<void> _showErrorDialog(String message) async {}
}
