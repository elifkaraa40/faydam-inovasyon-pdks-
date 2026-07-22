import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'services/api_service.dart';
import 'utils/download_file.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _api = ApiService();
  late DateTime _to = DateTime.now();
  late DateTime _from = _to.subtract(const Duration(days: 29));
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _exporting = false;
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
      final rows = await _api.getAttendanceRange(from: _from, to: _to);
      if (mounted) setState(() => _rows = rows);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 365 * 2));
    final lastDate = DateTime.now();
    final start = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: _from,
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: lastDate,
      initialDate: _to.isBefore(start) ? start : _to,
    );
    if (end == null || !mounted) return;
    if (end.difference(start).inDays > 89) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tarih aralığı en fazla 90 gün olabilir.')),
      );
      return;
    }
    setState(() {
      _from = start;
      _to = end;
    });
    await _load();
  }

  Future<void> _export(String format) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _api.exportAttendance(
        from: _from,
        to: _to,
        format: format,
      );
      final fileName =
          'puantajim-${_compactDate(_from)}-${_compactDate(_to)}.$format';
      final path = await downloadFile(
        bytes,
        fileName,
        format == 'pdf'
            ? 'application/pdf'
            : format == 'xlsx'
                ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                : 'text/csv;charset=utf-8',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Puantaj dosyası hazırlandı: $path')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  String _compactDate(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
  String _time(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return parsed == null
        ? '—'
        : '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    final background = dark ? AppColors.darkNavy : AppColors.lightBackground;
    final card = dark ? AppColors.cardNavy : Colors.white;
    final text = dark ? Colors.white : AppColors.darkNavy;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Puantajım'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: AppColors.neonTurquoise),
                    const SizedBox(width: 12),
                    Text('${_date(_from)} – ${_date(_to)}',
                        style: TextStyle(
                            color: text, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exporting ? null : () => _export('csv'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.darkNavy,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('CSV indir'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exporting ? null : () => _export('xlsx'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF198754),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Excel indir'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exporting ? null : () => _export('pdf'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('PDF indir'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _rows.isEmpty
                            ? ListView(children: const [
                                SizedBox(height: 160),
                                Center(
                                    child: Text(
                                        'Bu aralıkta puantaj kaydı bulunmuyor.'))
                              ])
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: _rows.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final row = _rows[index];
                                  return Card(
                                    color: card,
                                    child: ListTile(
                                      leading: const Icon(Icons.access_time,
                                          color: AppColors.neonTurquoise),
                                      title: Text(
                                          row['workDate']?.toString() ?? '—',
                                          style: TextStyle(
                                              color: text,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                          'Giriş ${_time(row['firstEntry'])} • Çıkış ${_time(row['lastExit'])}\n${row['status'] ?? '—'}',
                                          style: TextStyle(
                                              color:
                                                  text.withValues(alpha: .7))),
                                      isThreeLine: true,
                                      trailing: Text(
                                          '${(row['workedMinutes'] as num?)?.toInt() ?? 0} dk',
                                          style: const TextStyle(
                                              color: AppColors.neonTurquoise,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
