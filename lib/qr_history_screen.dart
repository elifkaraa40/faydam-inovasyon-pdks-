import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'app_provider.dart' hide AppColors;
import 'services/api_service.dart';

class QrHistoryScreen extends StatefulWidget {
  const QrHistoryScreen({super.key});

  @override
  State<QrHistoryScreen> createState() => _QrHistoryScreenState();
}

class _QrHistoryScreenState extends State<QrHistoryScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getQrAttendanceHistory();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final english = settings.isEnglish;
    final dark = settings.isDarkMode;
    final background = dark ? AppColors.darkNavy : AppColors.lightBackground;
    final card = dark ? AppColors.cardNavy : Colors.white;
    final text = dark ? Colors.white : AppColors.darkNavy;
    final secondary = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(english ? 'QR transaction history' : 'QR İşlem Geçmişi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 42),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _load,
                          child: Text(english ? 'Try again' : 'Tekrar dene'),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 150),
                          Icon(Icons.qr_code_2, color: secondary, size: 52),
                          const SizedBox(height: 12),
                          Text(
                            english
                                ? 'No QR transactions yet.'
                                : 'Henüz QR işlemi bulunmuyor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: secondary),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final entry =
                              item['eventType']?.toString().toLowerCase() ==
                                  'entry';
                          final occurredAt = DateTime.tryParse(
                                  item['occurredAt']?.toString() ?? '')
                              ?.toLocal();
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.neonTurquoise
                                      .withValues(alpha: .14),
                                  child: Icon(
                                    entry ? Icons.login : Icons.logout,
                                    color: AppColors.neonTurquoise,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry
                                            ? (english ? 'Entry' : 'Giriş')
                                            : (english ? 'Exit' : 'Çıkış'),
                                        style: TextStyle(
                                          color: text,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(occurredAt, english),
                                        style: TextStyle(color: secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatTime(occurredAt),
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _formatDate(DateTime? value, bool english) {
    if (value == null) return '—';
    if (english) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '—';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
