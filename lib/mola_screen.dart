import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'models/break_models.dart';
import 'services/api_service.dart';

class MolaScreen extends StatefulWidget {
  const MolaScreen({super.key});

  @override
  State<MolaScreen> createState() => _MolaScreenState();
}

class _MolaScreenState extends State<MolaScreen> {
  final ApiService _apiService = ApiService();
  CurrentBreak _current = const CurrentBreak(isOnBreak: false);
  List<BreakHistoryItem> _history = [];
  List<ActiveColleagueBreak> _colleagues = [];
  Timer? _timer;
  bool _isLoading = true;
  bool _isChanging = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _current.isOnBreak) setState(() {});
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final values = await Future.wait<Object>([
        _apiService.getCurrentBreak(),
        _apiService.getBreakHistory(
          from: DateTime(now.year, now.month),
          to: now,
        ),
        _apiService.getActiveColleagueBreaks(),
      ]);
      if (!mounted) return;
      setState(() {
        _current = values[0] as CurrentBreak;
        _history = values[1] as List<BreakHistoryItem>;
        _colleagues = values[2] as List<ActiveColleagueBreak>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBreak() async {
    if (_isChanging) return;
    setState(() {
      _isChanging = true;
      _error = null;
    });
    try {
      if (_current.isOnBreak) {
        final id = _current.breakId;
        if (id == null || id.isEmpty) {
          throw const ApiException('Aktif mola kimliği bulunamadı.');
        }
        await _apiService.endBreak(id);
      } else {
        await _apiService.startBreak();
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  Duration get _currentDuration {
    final startedAt = _current.startedAt;
    if (!_current.isOnBreak || startedAt == null) return Duration.zero;
    final value = DateTime.now().difference(startedAt.toLocal());
    return value.isNegative ? Duration.zero : value;
  }

  // Vardiya ayarlarında tanımlı standart aylık mola hakkı.
  // API ileride kullanıcı/shift bazlı hakkı döndürdüğünde bu değer oradan alınacak.
  static const int _monthlyBreakLimitMinutes = 60;
  int get _usedBreakSeconds {
    var total = 0;
    for (final item in _history) {
      if (item.endedAt != null) total += _effectiveSeconds(item.startedAt, item.endedAt!);
    }
    if (_current.isOnBreak && _current.startedAt != null) {
      total += _effectiveSeconds(_current.startedAt!, DateTime.now());
    }
    return total;
  }

  int get _remainingBreakSeconds =>
      _monthlyBreakLimitMinutes * 60 - _usedBreakSeconds;

  String get _remainingLabel {
    final seconds = _remainingBreakSeconds;
    final sign = seconds < 0 ? '-' : '';
    final absolute = seconds.abs();
    final hours = (absolute ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((absolute % 3600) ~/ 60).toString().padLeft(2, '0');
    final remainder = (absolute % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes:$remainder';
  }

  int _effectiveSeconds(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return 0;
    var effectiveSeconds = end.difference(start).inSeconds;
    for (var day = DateTime(start.year, start.month, start.day);
        !day.isAfter(DateTime(end.year, end.month, end.day));
        day = day.add(const Duration(days: 1))) {
      final lunchStart = DateTime(day.year, day.month, day.day, 12, 30);
      final lunchEnd = DateTime(day.year, day.month, day.day, 13, 30);
      final overlapStart = start.isAfter(lunchStart) ? start : lunchStart;
      final overlapEnd = end.isBefore(lunchEnd) ? end : lunchEnd;
      if (overlapEnd.isAfter(overlapStart)) {
        effectiveSeconds -= overlapEnd.difference(overlapStart).inSeconds;
      }
    }
    return effectiveSeconds;
  }

  String _duration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _dateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${_time(local)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final borderColor = isDark
        ? Colors.white.withValues(alpha: .05)
        : Colors.black.withValues(alpha: .05);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(en ? 'Break Management' : 'Mola Yönetimi',
            style: TextStyle(
                color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: _isLoading ? null : _load,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          en ? 'Elapsed Break' : 'Geçen Mola',
                          _duration(_currentDuration),
                          AppColors.neonTurquoise,
                          cardBg,
                          subTextColor,
                          borderColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _statCard(
                          en ? 'Remaining Break' : 'Kalan Mola',
                          _remainingLabel,
                          AppColors.accentOrange,
                          cardBg,
                          subTextColor,
                          borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? .2 : .05),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _current.isOnBreak ? null : 0,
                              strokeWidth: 10,
                              backgroundColor:
                                  isDark ? Colors.white10 : Colors.black12,
                              color: AppColors.neonTurquoise,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _current.isOnBreak
                                    ? CupertinoIcons.timer_fill
                                    : CupertinoIcons.timer,
                                size: 36,
                                color: _current.isOnBreak
                                    ? AppColors.neonTurquoise
                                    : subTextColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _current.isOnBreak
                                    ? (en ? 'On Break' : 'Moladasınız')
                                    : (en ? 'Working' : 'Çalışıyorsunuz'),
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              if (_current.isOnBreak)
                                Text(_duration(_currentDuration),
                                    style: TextStyle(
                                        color: subTextColor, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _current.isOnBreak
                            ? Colors.redAccent
                            : AppColors.neonTurquoise,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isChanging ? null : _toggleBreak,
                      icon: _isChanging
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _current.isOnBreak
                                  ? CupertinoIcons.stop_fill
                                  : CupertinoIcons.play_fill,
                              color: _current.isOnBreak
                                  ? Colors.white
                                  : AppColors.darkNavy,
                            ),
                      label: Text(
                        _current.isOnBreak ? (en ? 'End Break' : 'Molayı Bitir') : (en ? 'Start Break' : 'Molayı Başlat'),
                        style: TextStyle(
                            color: _current.isOnBreak
                                ? Colors.white
                                : AppColors.darkNavy,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 30),
                  Text(en ? 'Colleagues on Break' : 'Moladaki Arkadaşlarım',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_colleagues.isEmpty)
                    _emptyCard('Şu anda molada olan çalışma arkadaşınız yok.',
                        cardBg, subTextColor, borderColor)
                  else
                    ..._colleagues.map((item) => _colleagueCard(
                        item, cardBg, textColor, subTextColor, borderColor)),
                  const SizedBox(height: 26),
                  Text(en ? 'My Break History' : 'Mola Geçmişim',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    _emptyCard('Bu ay için mola kaydınız bulunmuyor.', cardBg,
                        subTextColor, borderColor)
                  else
                    ..._history.map((item) => _historyCard(
                        item, cardBg, textColor, subTextColor, borderColor)),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, Color valueColor,
          Color background, Color subText, Color border) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: subText, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _emptyCard(
          String message, Color background, Color subText, Color border) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Text(message,
            textAlign: TextAlign.center, style: TextStyle(color: subText)),
      );

  Widget _colleagueCard(ActiveColleagueBreak item, Color background, Color text,
          Color subText, Color border) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.darkNavy,
            child: Icon(CupertinoIcons.person, color: AppColors.neonTurquoise),
          ),
          title: Text(item.fullName,
              style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          subtitle: Text(
            [
              if (item.department?.trim().isNotEmpty == true) item.department!,
              '${_time(item.startedAt)} itibarıyla molada',
            ].join(' • '),
            style: TextStyle(color: subText, fontSize: 11),
          ),
        ),
      );

  Widget _historyCard(BreakHistoryItem item, Color background, Color text,
          Color subText, Color border) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: ListTile(
          leading: const Icon(Icons.history, color: AppColors.neonTurquoise),
          title: Text('${item.durationMinutes ?? 0} dakika',
              style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${_dateTime(item.startedAt)}${item.endedAt == null ? '' : ' - ${_time(item.endedAt!)}'}${item.autoClosed ? '\nÇıkışta otomatik kapatıldı' : ''}',
            style: TextStyle(color: subText, fontSize: 11),
          ),
        ),
      );
}
