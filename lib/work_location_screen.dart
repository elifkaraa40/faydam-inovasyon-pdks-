import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'services/api_service.dart';
import 'work_location_overlap.dart';

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

  Future<void> _create({
    String initialLocationType = 'Field',
    String initialReason = '',
    String initialProject = '',
    String initialCustomer = '',
    String initialAddress = '',
  }) async {
    final en = context.read<AppSettings>().isEnglish;
    String locationType = initialLocationType;
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime start = today;
    DateTime end = today;
    final reason = TextEditingController(text: initialReason);
    final project = TextEditingController(text: initialProject);
    final customer = TextEditingController(text: initialCustomer);
    final address = TextEditingController(text: initialAddress);
    String? validationError;
    String? dateError;

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(en
              ? 'Work Location Request'
              : 'Çalışma Konumu Talebi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: locationType,
                  decoration: InputDecoration(
                      labelText: en ? 'Work type' : 'Çalışma türü'),
                  items: [
                    DropdownMenuItem(
                        value: 'Field',
                        child: Text(en ? 'Field work' : 'Saha görevi')),
                    DropdownMenuItem(
                        value: 'Remote',
                        child: Text(en ? 'Remote work' : 'Uzaktan çalışma')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => locationType = value!),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.date_range),
                  title: Text(en ? 'Date range' : 'Tarih aralığı'),
                  subtitle: Text('${_date(start)} – ${_date(end)}'),
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365)),
                      initialDateRange: DateTimeRange(start: start, end: end),
                    );
                    if (range != null) {
                      if (range.duration.inDays > 89) {
                        setDialogState(() {
                          dateError = en
                              ? 'The date range can be at most 90 days.'
                              : 'Tarih aralığı en fazla 90 gün olabilir.';
                        });
                        return;
                      }
                      setDialogState(() {
                        start = range.start;
                        end = range.end;
                        dateError = null;
                      });
                    }
                  },
                ),
                if (dateError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dateError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                TextField(
                    controller: project,
                    decoration: InputDecoration(
                        labelText: en
                            ? 'Project (optional)'
                            : 'Proje (isteğe bağlı)')),
                TextField(
                    controller: customer,
                    decoration: InputDecoration(
                        labelText: en
                            ? 'Customer (optional)'
                            : 'Müşteri (isteğe bağlı)')),
                if (locationType == 'Field')
                  TextField(
                      controller: address,
                      decoration: InputDecoration(
                          labelText: en ? 'Field address' : 'Saha adresi')),
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
                      labelText: en ? 'Description' : 'Açıklama',
                      errorText: validationError),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(en ? 'Cancel' : 'İptal')),
            FilledButton(
              onPressed: () {
                if (end.difference(start).inDays > 89) {
                  setDialogState(() {
                    dateError = en
                        ? 'The date range can be at most 90 days.'
                        : 'Tarih aralığı en fazla 90 gün olabilir.';
                  });
                  return;
                }
                if (reason.text.trim().length < 10) {
                  setDialogState(() => validationError = en
                      ? 'The description must be at least 10 characters.'
                      : 'Açıklama en az 10 karakter olmalıdır.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(en ? 'Submit' : 'Gönder'),
            ),
          ],
        ),
      ),
    );

    if (submit != true || !mounted) {
      reason.dispose();
      project.dispose();
      customer.dispose();
      address.dispose();
      return;
    }

    final reasonText = reason.text.trim();
    final projectText = project.text.trim();
    final customerText = customer.text.trim();
    final addressText = address.text.trim();
    reason.dispose();
    project.dispose();
    customer.dispose();
    address.dispose();

    try {
      await _api.createWorkLocationRequest(
        locationType: locationType,
        startDate: start,
        endDate: end,
        reason: reasonText,
        projectName: _nullable(projectText),
        customerName: _nullable(customerText),
        fieldAddress:
            locationType == 'Field' ? _nullable(addressText) : null,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      final overlap = WorkLocationOverlapDetails.fromException(error);
      if (overlap != null) {
        final tryAnotherDate =
            await _showWorkLocationOverlapDialog(overlap, en);
        if (tryAnotherDate && mounted) {
          await _create(
            initialLocationType: locationType,
            initialReason: reasonText,
            initialProject: projectText,
            initialCustomer: customerText,
            initialAddress: addressText,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<bool> _showWorkLocationOverlapDialog(
    WorkLocationOverlapDetails overlap,
    bool en,
  ) async {
    final range = overlap.formattedRange;
    final message = overlap.isLeave
        ? (en
            ? 'There is a pending or approved leave request in the selected date range.'
            : 'Seçtiğiniz tarih aralığında bekleyen veya onaylanmış bir izin kaydı bulunmaktadır.')
        : (en
            ? 'There is another pending or approved work location record in the selected date range.'
            : 'Seçtiğiniz tarih aralığında bekleyen veya onaylanmış başka bir çalışma konumu kaydı bulunmaktadır.');
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(en
                ? 'Work location date is not available'
                : 'Çalışma konumu tarihi uygun değil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (range != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    en
                        ? 'Existing record: $range'
                        : 'Mevcut kayıt: $range',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(en ? 'Close' : 'Kapat'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(en ? 'Try other dates' : 'Başka tarih dene'),
              ),
            ],
          ),
        ) ??
        false;
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
