import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'services/api_service.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final values = await _apiService.getLeaveRequests();
      if (!mounted) return;
      setState(() {
        _requests = values
            .whereType<Map>()
            .map((value) => Map<String, dynamic>.from(value))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _type(Object? value) {
    switch (value?.toString()) {
      case 'Annual':
      case '1':
        return 'Yıllık İzin';
      case 'Sick':
      case '2':
        return 'Sağlık İzni';
      case 'Excuse':
      case '3':
        return 'Mazeret İzni';
      case 'Unpaid':
      case '4':
        return 'Ücretsiz İzin';
      default:
        return value?.toString() ?? 'İzin';
    }
  }

  String _status(Object? value) {
    switch (value?.toString()) {
      case 'Pending':
      case '1':
        return 'Beklemede';
      case 'Approved':
      case '2':
        return 'Onaylandı';
      case 'Rejected':
      case '3':
        return 'Reddedildi';
      case 'Cancelled':
      case '4':
        return 'İptal edildi';
      default:
        return value?.toString() ?? 'Bilinmiyor';
    }
  }

  bool _pending(Object? value) =>
      value?.toString() == 'Pending' || value?.toString() == '1';

  Future<void> _cancel(Object id) async {
    await _apiService.deleteLeaveRequest(id);
    await _load();
  }

  Future<void> _showCreateForm() async {
    String type = 'Annual';
    DateTime start = DateTime.now();
    DateTime end = DateTime.now();
    final reason = TextEditingController();
    String? reasonError;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni İzin Talebi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(
                        value: 'Annual', child: Text('Yıllık izin')),
                    DropdownMenuItem(value: 'Sick', child: Text('Sağlık izni')),
                    DropdownMenuItem(
                        value: 'Excuse', child: Text('Mazeret izni')),
                    DropdownMenuItem(
                        value: 'Unpaid', child: Text('Ücretsiz izin')),
                  ],
                  onChanged: (value) => setDialogState(() => type = value!),
                ),
                ListTile(
                  title: const Text('Başlangıç'),
                  subtitle: Text(_date(start)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: start,
                    );
                    if (value != null) {
                      setDialogState(() {
                        start = value;
                        if (end.isBefore(start)) end = start;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('Bitiş'),
                  subtitle: Text(_date(end)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: start,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: end.isBefore(start) ? start : end,
                    );
                    if (value != null) setDialogState(() => end = value);
                  },
                ),
                TextField(
                  controller: reason,
                  onChanged: (_) {
                    if (reasonError != null) {
                      setDialogState(() => reasonError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    errorText: reasonError,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal')),
            FilledButton(
                onPressed: () {
                  if (reason.text.trim().isEmpty) {
                    setDialogState(() =>
                        reasonError = 'İzin talebi için açıklama zorunludur.');
                    return;
                  }
                  if (end.isBefore(start)) {
                    setDialogState(() => reasonError =
                        'Bitiş tarihi başlangıç tarihinden önce olamaz.');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Gönder')),
          ],
        ),
      ),
    );
    if (submitted != true || !mounted) {
      reason.dispose();
      return;
    }
    try {
      await _apiService.createLeaveRequest(
        leaveType: type,
        startDate: _date(start),
        endDate: _date(end),
        reason: reason.text.trim(),
        dayPortion: 'FullDay',
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      reason.dispose();
    }
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    final cardColor = isDark ? AppColors.cardNavy : Colors.white;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('İzin Taleplerim', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _requests.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 180),
                          Center(
                              child: Text('Kayıtlı izin talebi bulunmuyor.')),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final item = _requests[index];
                            final status = item['status'];
                            return Card(
                              color: cardColor,
                              child: ListTile(
                                title: Text(_type(item['leaveType']),
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${item['startDate'] ?? ''} - ${item['endDate'] ?? ''}\n${item['reason'] ?? ''}\nDurum: ${_status(status)}',
                                  style: TextStyle(
                                      color: textColor.withValues(alpha: .7)),
                                ),
                                isThreeLine: true,
                                trailing: _pending(status) && item['id'] != null
                                    ? IconButton(
                                        onPressed: () => _cancel(item['id']),
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.redAccent),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateForm,
        backgroundColor: AppColors.neonTurquoise,
        icon: const Icon(Icons.add, color: AppColors.darkNavy),
        label: const Text('Yeni Talep',
            style: TextStyle(color: AppColors.darkNavy)),
      ),
    );
  }
}
