import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'app_colors.dart';
import 'app_provider.dart' hide AppColors;
import 'services/api_service.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _uuid = const Uuid();

  late final AnimationController _animationController;
  late final Animation<double> _scannerAnimation;
  bool _isProcessing = false;
  String _status = 'idle';
  String? _message;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scannerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _status != 'idle') return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _message = 'Kayıt doğrulanıyor...';
    });
    try {
      final response = await _api.scanAttendanceQr(
        qrValue: rawValue,
        occurredAt: DateTime.now().toUtc().toIso8601String(),
        deviceEventId: _uuid.v4(),
      );
      if (!mounted) return;
      final eventType = response['eventType']?.toString().toLowerCase();
      setState(() {
        if (eventType == 'entry') {
          _status = 'success_in';
          _message = 'Giriş onaylandı!';
        } else if (eventType == 'exit') {
          _status = 'success_out';
          _message = 'Çıkış onaylandı!';
        } else {
          _status = 'success';
          _message = response['message']?.toString() ?? 'Puantaj kaydı alındı.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _message = error.toString();
      });
    } finally {
      _isProcessing = false;
      _scheduleReset();
    }
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _status = 'idle';
          _message = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;
    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    final feedbackColor = _status == 'error'
        ? Colors.redAccent
        : _status == 'success_in'
            ? Colors.greenAccent
            : AppColors.neonTurquoise;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'QR Okuyucu',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _status == 'idle'
                      ? _scannerCard(cardBg)
                      : _feedbackCard(cardBg, feedbackColor),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _message ?? 'Giriş/çıkış QR kodunu çerçeveye hizalayın',
                    key: ValueKey('$_status-$_message'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _status == 'idle'
                          ? (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600)
                          : feedbackColor,
                      fontSize: 15,
                      fontWeight:
                          _status == 'idle' ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kayıt türü ve geçerliliği sunucu tarafından doğrulanır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scannerCard(Color cardBg) {
    return Container(
      key: const ValueKey('scanner'),
      width: 280,
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.neonTurquoise.withValues(alpha: .5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonTurquoise.withValues(alpha: .15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Kamera açılamadı: ${error.errorDetails?.message ?? error.errorCode.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _scannerAnimation,
                builder: (context, child) => Align(
                  alignment: Alignment(0, (_scannerAnimation.value * 2) - 1),
                  child: child,
                ),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.neonTurquoise,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonTurquoise.withValues(alpha: .8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackCard(Color cardBg, Color color) {
    final isError = _status == 'error';
    return Container(
      key: ValueKey(_status),
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(
              isError ? Icons.close_rounded : Icons.check_rounded,
              color: color,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isError ? 'İŞLEM BAŞARISIZ' : 'KAYIT BAŞARILI',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
