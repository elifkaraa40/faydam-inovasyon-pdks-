import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'services/api_service.dart';

class AttendanceCorrectionScreen extends StatefulWidget {
  const AttendanceCorrectionScreen({super.key});
  @override State<AttendanceCorrectionScreen> createState() => _AttendanceCorrectionScreenState();
}

class _AttendanceCorrectionScreenState extends State<AttendanceCorrectionScreen> {
  final _api = ApiService();
  DateTime _date = DateTime.now().subtract(const Duration(days: 1));
  final _entry = TextEditingController(text: '08:30');
  final _exit = TextEditingController(text: '18:00');
  final _reason = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _sending = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _entry.dispose(); _exit.dispose(); _reason.dispose(); super.dispose(); }
  Future<void> _load() async { setState(() => _loading = true); try { final v = await _api.getAttendanceCorrections(); if (mounted) setState(() => _items = v); } catch (e) { if (mounted) _message('$e', true); } finally { if (mounted) setState(() => _loading = false); } }
  String _dateText(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  String _status(Object? s) => switch (s?.toString()) { 'Approved' || '1' => 'Onaylandı', 'Rejected' || '2' => 'Reddedildi', 'Cancelled' || '3' => 'İptal edildi', _ => 'Bekliyor' };
  Future<void> _send() async {
    if (_reason.text.trim().length < 10) { _message('Gerekçe en az 10 karakter olmalıdır.', true); return; }
    final now = DateTime.now();
    if (!_date.isBefore(DateTime(now.year, now.month, now.day))) {
      _message('Puantaj düzeltme talebi sadece geçmiş tarihler için oluşturulabilir.', true);
      return;
    }
    setState(() => _sending = true);
    try { await _api.createAttendanceCorrection(workDate: _date, requestedEntry: _entry.text, requestedExit: _exit.text, reason: _reason.text.trim()); _reason.clear(); await _load(); _message('Düzeltme talebi onaya gönderildi.', false); } catch (e) { _message('$e', true); } finally { if (mounted) setState(() => _sending = false); }
  }
  DateTime? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]); final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    final now = DateTime.now(); return DateTime(now.year, now.month, now.day, hour, minute);
  }
  void _message(String text, bool error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.redAccent : null));
  @override Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>(); final dark = settings.isDarkMode; final en = settings.isEnglish; final text = dark ? Colors.white : AppColors.darkNavy;
    return Scaffold(backgroundColor: dark ? AppColors.darkNavy : AppColors.lightBackground, appBar: AppBar(title: Text(en ? 'Attendance correction' : 'Puantaj düzeltme'), backgroundColor: Colors.transparent, elevation: 0), body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: dark ? AppColors.cardNavy : Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(en ? 'Missing or incorrect record' : 'Eksik veya hatalı kayıt'), const SizedBox(height: 12),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month), title: const Text('Çalışma tarihi'), subtitle: Text(_dateText(_date)), onTap: () async { final v = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 90)), lastDate: DateTime.now(), initialDate: _date); if (v != null) setState(() => _date = v); }),
        Row(children: [Expanded(child: TextField(controller: _entry, decoration: InputDecoration(labelText: en ? 'Entry' : 'Giriş', prefixIcon: const Icon(Icons.login)), keyboardType: TextInputType.datetime)), const SizedBox(width: 12), Expanded(child: TextField(controller: _exit, decoration: InputDecoration(labelText: en ? 'Exit' : 'Çıkış', prefixIcon: const Icon(Icons.logout)), keyboardType: TextInputType.datetime))]),
        const SizedBox(height: 12), TextField(controller: _reason, minLines: 3, maxLines: 4, decoration: const InputDecoration(labelText: 'Gerekçe', hintText: 'En az 10 karakter', border: OutlineInputBorder())), const SizedBox(height: 12), FilledButton(onPressed: _sending ? null : _send, child: Text(_sending ? 'Gönderiliyor…' : 'Onaya gönder')),
      ]))), const SizedBox(height: 20), Text('Taleplerim', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      if (_loading) const Center(child: CircularProgressIndicator()) else if (_items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Henüz düzeltme talebi yok.'))) else ..._items.map((item) => Card(color: dark ? AppColors.cardNavy : Colors.white, child: ListTile(title: Text(item['workDate']?.toString() ?? 'Tarih', style: TextStyle(color: text, fontWeight: FontWeight.bold)), subtitle: Text('${item['requestedEntry'] ?? ''} – ${item['requestedExit'] ?? ''}\n${item['reason'] ?? ''}'), trailing: Text(_status(item['status']))))),
    ])));
  }
}
