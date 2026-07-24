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
  String? _exportingFormat;
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
    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range == null || !mounted) return;
    if (range.duration.inDays > 89) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tarih aralığı en fazla 90 gün olabilir.')),
      );
      return;
    }
    setState(() {
      _from = range.start;
      _to = range.end;
    });
    await _load();
  }

  Future<void> _export(String format) async {
    if (_exportingFormat != null) return;
    final en = context.read<AppSettings>().isEnglish;
    setState(() => _exportingFormat = format);
    try {
      final bytes = await _api.exportAttendance(
        from: _from,
        to: _to,
        format: format,
        language: en ? 'en' : 'tr',
      );
      final fileName =
          'puantajim-${_compactDate(_from)}-${_compactDate(_to)}.$format';
      final file = await downloadFile(
        bytes,
        fileName,
        format == 'pdf'
            ? 'application/pdf'
            : format == 'xlsx'
                ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                : 'text/csv;charset=utf-8',
        subdirectory: 'Puantaj',
      );
      if (mounted) {
        await _showFileReady(file, en);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              en
                  ? 'The file could not be downloaded: $error'
                  : 'Dosya indirilemedi: $error',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingFormat = null);
    }
  }

  Future<void> _showFileReady(DownloadedFile file, bool en) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(en ? 'File ready' : 'Dosya hazır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              en ? 'File name' : 'Dosya adı',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(file.fileName),
            const SizedBox(height: 14),
            Text(
              en ? 'Saved folder' : 'Kaydedilen klasör',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(file.displayLocation),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(en ? 'Close' : 'Kapat'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final result = await openDownloadedFile(file);
              if (!dialogContext.mounted) return;
              if (result == OpenDownloadedFileResult.opened) {
                Navigator.pop(dialogContext);
                return;
              }
              Navigator.pop(dialogContext);
              if (!mounted) return;
              await _showFileOpenError(result, en);
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(en ? 'Open file' : 'Dosyayı aç'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFileOpenError(
    OpenDownloadedFileResult result,
    bool en,
  ) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(en ? 'File could not be opened' : 'Dosya açılamadı'),
          content: Text(
            result == OpenDownloadedFileResult.noApplication
                ? (en
                    ? 'No application capable of opening this file was found on the device.'
                    : 'Cihazda bu dosyayı açabilecek uygun bir uygulama bulunamadı.')
                : (en
                    ? 'An error occurred while opening the file. You can access it from the saved folder.'
                    : 'Dosya açılırken bir hata oluştu. Dosyaya kaydedilen klasörden erişebilirsiniz.'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(en ? 'Close' : 'Kapat'),
            ),
          ],
        ),
      );

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
    final en = context.watch<AppSettings>().isEnglish;
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
                    onPressed:
                        _exportingFormat != null ? null : () => _export('csv'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.darkNavy,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: _exportButtonContent(
                      format: 'csv',
                      label: en ? 'Download CSV' : 'CSV indir',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _exportingFormat != null ? null : () => _export('xlsx'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF198754),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: _exportButtonContent(
                      format: 'xlsx',
                      label: en ? 'Download Excel' : 'Excel indir',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _exportingFormat != null ? null : () => _export('pdf'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: _exportButtonContent(
                      format: 'pdf',
                      label: en ? 'Download PDF' : 'PDF indir',
                    ),
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

  Widget _exportButtonContent({
    required String format,
    required String label,
  }) {
    if (_exportingFormat != format) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label)),
      ],
    );
  }
}
