import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'services/api_service.dart';

class WorkLocationScreen extends StatefulWidget {
  const WorkLocationScreen({super.key});

  @override
  State<WorkLocationScreen> createState() => _WorkLocationScreenState();
}

class _WorkLocationScreenState extends State<WorkLocationScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _requests = [];
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
      final values = await _api.getWorkLocationRequests();
      if (mounted) setState(() => _requests = values);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    String locationType = 'Field';
    DateTime start = DateTime.now();
    DateTime end = DateTime.now();
    final reason = TextEditingController();
    final project = TextEditingController();
    final customer = TextEditingController();
    final address = TextEditingController();
    String? validationError;

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Çalışma Konumu Talebi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: locationType,
                  decoration: const InputDecoration(labelText: 'Çalışma türü'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Field', child: Text('Saha görevi')),
                    DropdownMenuItem(
                        value: 'Remote', child: Text('Uzaktan çalışma')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => locationType = value!),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bitiş'),
                  subtitle: Text(_date(end)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: start,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: end,
                    );
                    if (value != null) setDialogState(() => end = value);
                  },
                ),
                TextField(
                    controller: project,
                    decoration: const InputDecoration(
                        labelText: 'Proje (isteğe bağlı)')),
                TextField(
                    controller: customer,
                    decoration: const InputDecoration(
                        labelText: 'Müşteri (isteğe bağlı)')),
                if (locationType == 'Field')
                  TextField(
                      controller: address,
                      decoration:
                          const InputDecoration(labelText: 'Saha adresi')),
                TextField(
                  controller: reason,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                  decoration: InputDecoration(
                      labelText: 'Açıklama', errorText: validationError),
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
                if (reason.text.trim().length < 10) {
                  setDialogState(() => validationError =
                      'Açıklama en az 10 karakter olmalıdır.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );

    if (submit == true && mounted) {
      try {
        await _api.createWorkLocationRequest(
          locationType: locationType,
          startDate: start,
          endDate: end,
          reason: reason.text.trim(),
          projectName: _nullable(project.text),
          customerName: _nullable(customer.text),
          fieldAddress:
              locationType == 'Field' ? _nullable(address.text) : null,
        );
        await _load();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('$error'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
    reason.dispose();
    project.dispose();
    customer.dispose();
    address.dispose();
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  bool _pending(Object? value) =>
      value?.toString() == 'Pending' || value?.toString() == '1';

  Future<void> _cancel(Object id) async {
    try {
      await _api.cancelWorkLocationRequest(id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    final text = dark ? Colors.white : AppColors.darkNavy;
    final card = dark ? AppColors.cardNavy : Colors.white;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
          title: const Text('Çalışma Konumu'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: _loading
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
                              child: Text('Çalışma konumu talebi bulunmuyor.'))
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _requests[index];
                            final pending = _pending(item['status']);
                            return Card(
                              color: card,
                              child: ListTile(
                                leading: Icon(
                                    item['locationType']?.toString() == 'Remote'
                                        ? Icons.home_work_outlined
                                        : Icons.location_on_outlined,
                                    color: AppColors.neonTurquoise),
                                title: Text(
                                    item['locationType']?.toString() == 'Remote'
                                        ? 'Uzaktan Çalışma'
                                        : 'Saha Görevi',
                                    style: TextStyle(
                                        color: text,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${item['startDate'] ?? ''} – ${item['endDate'] ?? ''}\n${item['reason'] ?? ''}\nDurum: ${item['status'] ?? '—'}',
                                    style: TextStyle(
                                        color: text.withValues(alpha: .7))),
                                isThreeLine: true,
                                trailing: pending && item['id'] != null
                                    ? IconButton(
                                        onPressed: () => _cancel(item['id']!),
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.redAccent))
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.neonTurquoise,
        foregroundColor: AppColors.darkNavy,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Talep'),
      ),
    );
  }
}
