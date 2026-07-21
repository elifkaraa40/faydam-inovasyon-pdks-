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

  List<dynamic> _leaveRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // API'den gelen izin taleplerini list değişkenine alıyoruz
      final list = await _apiService.getLeaveRequests();

      if (!mounted) return;

      setState(() {
        _leaveRequests = list;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Hata: ${error.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewLeaveRequest() async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('İzin Tipi Seçin'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Annual',
                );
              },
              child: const Text(
                'Yıllık İzin (Annual)',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Sick',
                );
              },
              child: const Text(
                'Sağlık İzni (Sick)',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Excuse',
                );
              },
              child: const Text(
                'Mazeret İzni (Excuse)',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  'Unpaid',
                );
              },
              child: const Text(
                'Ücretsiz İzin (Unpaid)',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedType == null) return;

    final durationType = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('İzin Süresi'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'single'),
            child: const Text('Tek Günlük İzin'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'range'),
            child: const Text('Birden Fazla Gün'),
          ),
        ],
      ),
    );

    if (!mounted || durationType == null) return;

    late DateTimeRange pickedRange;
    if (durationType == 'single') {
      final pickedDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (!mounted || pickedDate == null) return;
      pickedRange = DateTimeRange(start: pickedDate, end: pickedDate);
    } else {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (!mounted || range == null) return;
      pickedRange = range;
    }

    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Açıklama Girin'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'İzin alma sebebi...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (!mounted || confirm != true || reason.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.createLeaveRequest(
        leaveType: selectedType,
        startDate: _formatDate(
          pickedRange.start,
        ),
        endDate: _formatDate(
          pickedRange.end,
        ),
        reason: reason,
        dayPortion: 'FullDay',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İzin talebiniz gönderildi.',
          ),
        ),
      );

      await _fetchLeaveRequests();
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Talep iletilemedi: $message',
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelLeaveRequest(
    Object requestId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Talebi İptal Et'),
          content: const Text(
            'Bu izin talebini iptal etmek '
            'istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Evet, İptal Et',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.deleteLeaveRequest(
        requestId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İzin talebi iptal edildi.',
          ),
        ),
      );

      await _fetchLeaveRequests();
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İptal işlemi başarısız: $message',
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _leaveTypeText(Object? value) {
    switch (value?.toString()) {
      case 'Annual':
      case '1':
        return 'Yıllık';

      case 'Sick':
      case '2':
        return 'Sağlık';

      case 'Excuse':
      case '3':
        return 'Mazeret';

      case 'Unpaid':
      case '4':
        return 'Ücretsiz';

      default:
        return value?.toString() ?? 'İzin';
    }
  }

  String _statusText(Object? value) {
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
        return 'İptal Edildi';

      default:
        return value?.toString() ?? 'Beklemede';
    }
  }

  bool _isPending(Object? value) {
    return value?.toString() == 'Pending' || value?.toString() == '1';
  }

  bool _isApproved(Object? value) {
    return value?.toString() == 'Approved' || value?.toString() == '2';
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor:
          settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'İzin Taleplerim',
          style: TextStyle(
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: Icon(
              Icons.refresh,
              color: textColor,
            ),
            onPressed: _isLoading ? null : _fetchLeaveRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.neonTurquoise,
              ),
            )
          : _leaveRequests.isEmpty
              ? Center(
                  child: Text(
                    'Henüz bir izin talebiniz '
                    'bulunmuyor.',
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLeaveRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaveRequests.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final rawItem = _leaveRequests[index];

                      if (rawItem is! Map) {
                        return const SizedBox.shrink();
                      }

                      final item = Map<String, dynamic>.from(
                        rawItem,
                      );

                      final status = item['status'];

                      return Card(
                        color: settings.isDarkMode
                            ? AppColors.cardNavy
                            : Colors.white,
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            '${_leaveTypeText(item['leaveType'])} İzni',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tarih: ${item['startDate']} - ${item['endDate']}",
                                style: TextStyle(
                                  color: textColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              Text(
                                "Açıklama: ${item['reason'] ?? ''}",
                                style: TextStyle(
                                  color: textColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              Text(
                                'Durum: ${_statusText(status)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isApproved(status)
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          trailing: _isPending(status)
                              ? IconButton(
                                  tooltip: 'Talebi iptal et',
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    final id = item['id'];

                                    if (id != null) {
                                      _cancelLeaveRequest(
                                        id,
                                      );
                                    }
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createNewLeaveRequest,
        backgroundColor: AppColors.neonTurquoise,
        child: const Icon(
          Icons.add,
          color: AppColors.darkNavy,
        ),
      ),
    );
  }
}
