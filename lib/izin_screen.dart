import 'package:flutter/material.dart';
import 'package:ilk_mobil_uygulamam/api_service.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'services/api_service.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({Key? key}) : super(key: key);

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
      final list = await _apiService.getLeaveRequests();
      setState(() {
        _leaveRequests = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İzin listesi yüklenemedi: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _createNewLeaveRequest() async {
    final String? selectedType = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("İzin Tipi Seçin"),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Annual'),
              child: const Text("Yıllık İzin (Annual)"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Sick'),
              child: const Text("Sağlık İzni (Sick)"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Excuse'),
              child: const Text("Mazeret İzni (Excuse)"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Unpaid'),
              child: const Text("Ücretsiz İzin (Unpaid)"),
            ),
          ],
        );
      },
    );

    if (selectedType == null) return;

    // Örnek hızlı tarih seçici simülasyonu (Gerçek tasarımdaki DateTime pickerlar ile güncellenebilir)
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedRange == null) return;

    final reasonController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Açıklama Girin"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: "İzin alma sebebi..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Gönder"),
            ),
          ],
        );
      },
    );

    if (confirm != true || reasonController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.createLeaveRequest(
        leaveType: selectedType,
        startDate: pickedRange.start.toIso8601String().split('T')[0],
        endDate: pickedRange.end.toIso8601String().split('T')[0],
        reason: reasonController.text.trim(),
      );
      _fetchLeaveRequests(); // Başarılı olunca listeyi yeniliyoruz
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Talep iletilemedi: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelLeaveRequest(int requestId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Talebi İptal Et"),
        content: const Text("Bu izin talebini iptal etmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet, İptal Et")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.deleteLeaveRequest(requestId);
      _fetchLeaveRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İptal işlemi başarısız: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final textColor = settings.isDarkMode ? Colors.white : AppColors.darkNavy;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text("İzin Taleplerim", style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _fetchLeaveRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonTurquoise))
          : _leaveRequests.isEmpty
              ? Center(child: Text("Henüz bir izin talebiniz bulunmuyor.", style: TextStyle(color: textColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _leaveRequests.length,
                  itemBuilder: (context, index) {
                    final item = _leaveRequests[index];
                    return Card(
                      color: settings.isDarkMode ? AppColors.cardNavy : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(
                          "${item['leaveType']} İzni",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tarih: ${item['startDate']} - ${item['endDate']}", style: TextStyle(color: textColor.withOpacity(0.7))),
                            Text("Açıklama: ${item['reason'] ?? ''}", style: TextStyle(color: textColor.withOpacity(0.7))),
                            Text("Durum: ${item['status'] ?? 'Beklemede'}", style: TextStyle(fontWeight: FontWeight.bold, color: item['status'] == 'Approved' ? Colors.green : Colors.orange)),
                          ],
                        ),
                        trailing: item['status'] == 'Pending'
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _cancelLeaveRequest(item['id']),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewLeaveRequest,
        backgroundColor: AppColors.neonTurquoise,
        child: const Icon(Icons.add, color: AppColors.darkNavy),
      ),
    );
  }
}