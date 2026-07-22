import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe'; 
import 'dart:ui_web' as ui_web; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web; 
import 'app_provider.dart' hide AppColors; 
import 'app_colors.dart';

// Tarayıcıdaki global jsQR kütüphanesine erişmek için JS interop tanımı
@JS('jsQR')
external JSPromise? jsQR(JSObject data, int width, int height, JSObject? options);

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> with SingleTickerProviderStateMixin {
  String _status = "idle"; 
  bool _lastActionWasCheckIn = false; 
  bool _isProcessing = false;
  
  late AnimationController _animationController;
  late Animation<double> _scannerAnimation;
  
  web.HTMLVideoElement? _videoElement;
  web.HTMLCanvasElement? _canvasElement;
  Timer? _scanTimer;
  final String _viewId = 'web-camera-view';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    if (kIsWeb) {
      _injectJsQrLibrary();
      _initializeWebCamera();
    }
  }

  // jsQR kütüphanesini dinamik olarak HTML sayfasına enjekte eder
  void _injectJsQrLibrary() {
    final scripts = web.document.getElementsByTagName('script');
    for (int i = 0; i < scripts.length; i++) {
      final script = scripts.item(i) as web.HTMLScriptElement?;
      if (script?.src.contains('jsQR') ?? false) return;
    }
    final scriptElement = web.HTMLScriptElement()
      ..src = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js';
    web.document.head?.appendChild(scriptElement);
  }

  Future<void> _initializeWebCamera() async {
    _canvasElement = web.HTMLCanvasElement();
    
    _videoElement = web.HTMLVideoElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      // Kameranın ters (ayna gibi) görünmesini düzelten CSS sihirbazlığı:
      ..style.transform = 'scaleX(-1)'
      ..autoplay = true;
    
    _videoElement!.setAttribute('playsinline', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _videoElement!,
    );

    try {
      final navigator = web.window.navigator;
      final mediaDevices = navigator.mediaDevices;
      
      if (mediaDevices != null) {
        final constraints = web.MediaStreamConstraints(
          video: true.toJS, 
          audio: false.toJS,
        );
        
        final jsStream = await mediaDevices.getUserMedia(constraints).toDart;
        
        if (_videoElement != null && jsStream != null) {
          _videoElement!.srcObject = jsStream as web.MediaProvider?;
          _videoElement!.play(); 
          
          // Kamera başarıyla açıldıktan sonra QR kodları aramaya başla
          _startQrDecoding();
        }
      }
    } catch (error) {
      debugPrint("Kamera başlatma hatası: $error");
    }
  }

  // Sürekli olarak video karesini yakalayıp QR kod var mı diye kontrol eden döngü
  void _startQrDecoding() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_videoElement == null || _canvasElement == null || _isProcessing || _status != "idle") return;
      if (_videoElement!.videoWidth == 0 || _videoElement!.videoHeight == 0) return;

      final width = _videoElement!.videoWidth;
      final height = _videoElement!.videoHeight;
      
      _canvasElement!.width = width;
      _canvasElement!.height = height;
      
      final ctx = _canvasElement!.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) return;

      // Videodan anlık kareyi al
      ctx.drawImage(_videoElement! as web.CanvasImageSource, 0, 0, width.toJS as num, height.toJS as num);
      
      try {
        final imageData = ctx.getImageData(0, 0, width, height);
        // Tarayıcıdaki jsQR fonksiyonunu tetikle
        final jsContext = web.window as JSObject;
        if (jsContext.hasProperty('jsQR' as JSAny).toDart) {
          final code = jsContext.callMethod(
            'jsQR'.toJS, 
            imageData.data, 
            width.toJS, 
            height.toJS
          ) as JSObject?;
          
          if (code != null && code.hasProperty('data' as JSAny).toDart) {
            final String qrResult = (code.getProperty('data'.toJS) as JSString).toDart;
            if (qrResult.isNotEmpty) {
              _processQrCode(qrResult);
            }
          }
        }
      } catch (e) {
        // Kütüphane yüklenene kadar ilk birkaç kare hata verebilir, yutuyoruz.
      }
    });
  }

  void _processQrCode(String result) {
    _isProcessing = true;
    final lowercaseResult = result.toLowerCase();
    
    // QR kod içeriğinde giriş mi çıkış mı yazıyor kontrolü
    if (lowercaseResult.contains('giriş') || lowercaseResult.contains('in')) {
      _handleQrScan(true);
    } else if (lowercaseResult.contains('çıkış') || lowercaseResult.contains('out')) {
      _handleQrScan(false);
    } else {
      // Bilinmeyen farklı bir QR okunduysa genel hata ver
      setState(() {
        _status = "error_in";
      });
      Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _status = "idle");
      });
    }
    
    _isProcessing = false;
  }

  void _handleQrScan(bool isCheckInAction) {
    setState(() {
      if (isCheckInAction) {
        if (_lastActionWasCheckIn) {
          _status = "error_in"; 
        } else {
          _status = "success_in";
          _lastActionWasCheckIn = true;
        }
      } else {
        if (!_lastActionWasCheckIn) {
          _status = "error_out"; 
        } else {
          _status = "success_out";
          _lastActionWasCheckIn = false;
        }
      }
    });

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _status = "idle";
        });
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _animationController.dispose();
    if (_videoElement != null && _videoElement!.srcObject != null) {
      try {
        final stream = _videoElement!.srcObject as web.MediaStream?;
        stream?.getTracks().forEach((track) {
          (track as web.MediaStreamTrack).stop();
        });
      } catch (e) {
        debugPrint("Kamera kapatma hatası: $e");
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isDark = settings.isDarkMode;

    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    
    String statusText = "Align QR Code for Check-in/out";
    Color statusColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    if (_status == "success_in") {
      statusText = "Giriş Onaylandı!";
      statusColor = Colors.greenAccent;
    } else if (_status == "success_out") {
      statusText = "Çıkış Onaylandı!";
      statusColor = AppColors.neonTurquoise;
    } else if (_status.startsWith("error")) {
      statusText = _status == "error_in" ? "HATA: Zaten Giriş Yapılmış!" : "HATA: Zaten Çıkış Yapılmış!";
      statusColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          "QR Scanner",
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _buildStateWidget(cardBg),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    statusText,
                    key: ValueKey<String>(_status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 15,
                      fontWeight: _status == "idle" ? FontWeight.w500 : FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateWidget(Color cardBg) {
    if (_status == "idle") {
      return _buildScannerWidget(cardBg);
    } else if (_status.startsWith("success")) {
      final isSubActionIn = _status == "success_in";
      return _buildFeedbackWidget(
        key: 'success',
        title: isSubActionIn ? "GİRİŞ BAŞARILI" : "ÇIKIŞ BAŞARILI",
        color: isSubActionIn ? Colors.greenAccent : AppColors.neonTurquoise,
        icon: isSubActionIn ? CupertinoIcons.check_mark_circled : CupertinoIcons.arrow_right_circle,
        cardBg: cardBg,
      );
    } else {
      return _buildFeedbackWidget(
        key: 'error',
        title: "GEÇERSİZ İŞLEM",
        color: Colors.redAccent,
        icon: CupertinoIcons.exclamationmark_triangle,
        cardBg: cardBg,
      );
    }
  }

  Widget _buildScannerWidget(Color cardBg) {
    return Container(
      key: const ValueKey('scanner'),
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            kIsWeb
                ? HtmlElementView(viewType: _viewId)
                : Container(color: Colors.black87), 
            Container(color: Colors.black.withOpacity(0.05)),
            AnimatedBuilder(
              animation: _scannerAnimation,
              builder: (context, child) {
                return Positioned(
                  top: _scannerAnimation.value * 240,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonTurquoise.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ],
                      gradient: LinearGradient( 
                        colors: [Colors.transparent, AppColors.neonTurquoise, Colors.transparent],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackWidget({
    required String key,
    required String title,
    required Color color,
    required IconData icon,
    required Color cardBg,
  }) {
    return Container(
      key: ValueKey(key),
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Icon(
                icon,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on JSArray<web.MediaStreamTrack> {
  void forEach(Null Function(Stack) param0) {}
}