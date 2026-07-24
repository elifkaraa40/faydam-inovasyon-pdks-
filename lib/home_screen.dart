import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'notifications_screen.dart';
import 'services/api_service.dart';
import 'widgets/notification_badge_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Timer? _clockTimer;
  String _currentTime = '';
  String _currentDate = '';
  Map<String, dynamic>? _attendance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final value = await _apiService.getTodayAttendance();
      if (!mounted) return;
      setState(() => _attendance = value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _currentDate =
          '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    });
  }

  String? _firstValue(List<String> keys) {
    final data = _attendance;
    if (data == null) return null;
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String _formatTime(String? value) {
    if (value == null) return 'Kayıt yok';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed != null) {
      return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    }
    final match = RegExp(r'(\d{2}:\d{2})').firstMatch(value);
    return match?.group(1) ?? value;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final en = settings.isEnglish;
    final isDark = settings.isDarkMode;
    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final userName = settings.userName?.trim().isNotEmpty == true
        ? settings.userName!
        : 'Kullanıcı';
    final checkIn = _formatTime(_firstValue([
      'firstEntry',
      'checkInAt',
      'checkInTime',
      'firstCheckInAt',
      'entryTime',
      'startTime'
    ]));
    final checkOut = _formatTime(_firstValue([
      'lastExit',
      'checkOutAt',
      'checkOutTime',
      'lastCheckOutAt',
      'exitTime',
      'endTime'
    ]));
    final status = _firstValue(['status', 'attendanceStatus', 'dayStatus']) ?? 'Kayıt yok';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAttendance,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(en ? 'Welcome,' : 'Hoş Geldin,',
                          style: TextStyle(color: subTextColor)),
                      Text(userName,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Bildirimler',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    icon: const NotificationBadgeIcon(
                      icon: CupertinoIcons.bell_fill,
                      color: AppColors.neonTurquoise,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _card(
                cardBg,
                Column(
                  children: [
                    Text(_currentDate.toUpperCase(),
                        style: TextStyle(color: subTextColor, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text(_currentTime,
                        style: const TextStyle(
                            color: AppColors.neonTurquoise,
                            fontSize: 42,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(en ? 'Today\'s Attendance' : 'Bugünkü Devam Bilgisi',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _card(
                  cardBg,
                  Column(
                    children: [
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent)),
                      TextButton(
                          onPressed: _loadAttendance,
                          child: const Text('Tekrar dene')),
                    ],
                  ),
                )
              else
                _card(
                  cardBg,
                  Row(
                    children: [
                      Expanded(
                          child: _timeColumn(
                              'Giriş', checkIn, textColor, subTextColor)),
                      Container(width: 1, height: 42, color: Colors.white12),
                      Expanded(
                          child: _timeColumn(
                              'Çıkış', checkOut, textColor, subTextColor)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (!_isLoading && _error == null)
                _card(
                  cardBg,
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Güncel Durum', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _statusLine(en ? 'Last QR entry' : 'Son QR girişi', checkIn, Icons.login, textColor, subTextColor),
                    const SizedBox(height: 8),
                    _statusLine(en ? 'Last QR exit' : 'Son QR çıkışı', checkOut, Icons.logout, textColor, subTextColor),
                    const SizedBox(height: 8),
                    _statusLine(en ? 'Status' : 'Durum', status, Icons.info_outline, textColor, subTextColor),
                  ]),
                ),
              const SizedBox(height: 12),
              if (!_isLoading && _error == null)
                _card(
                  cardBg,
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _summaryValue(en ? 'Worked' : 'Çalışılan', _minutes('workedMinutes'),
                          textColor, subTextColor),
                      _summaryValue(en ? 'Expected' : 'Beklenen', _minutes('expectedMinutes'),
                          textColor, subTextColor),
                      _summaryValue(en ? 'Late' : 'Geç Kalma', _minutes('lateMinutes'),
                          textColor, subTextColor),
                      _summaryValue(en ? 'Overtime' : 'Fazla Mesai', _minutes('overtimeMinutes'),
                          textColor, subTextColor),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Color color, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );

  Widget _timeColumn(String label, String value, Color text, Color subText) =>
      Column(
        children: [
          Text(label, style: TextStyle(color: subText, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: text, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      );

  Widget _statusLine(String label, String value, IconData icon, Color text, Color subText) =>
      Row(children: [Icon(icon, color: AppColors.neonTurquoise, size: 20), const SizedBox(width: 10), Expanded(child: Text(label, style: TextStyle(color: subText))), Text(value, style: TextStyle(color: text, fontWeight: FontWeight.bold))]);

  String _minutes(String key) {
    final value = (_attendance?[key] as num?)?.toInt();
    if (value == null) return '—';
    final hours = value ~/ 60;
    final minutes = value % 60;
    return hours > 0 ? '${hours}s ${minutes}dk' : '${minutes}dk';
  }

  Widget _summaryValue(
    String label,
    String value,
    Color text,
    Color subText,
  ) =>
      SizedBox(
        width: 105,
        child: Column(
          children: [
            Text(label, style: TextStyle(color: subText, fontSize: 12)),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(color: text, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
