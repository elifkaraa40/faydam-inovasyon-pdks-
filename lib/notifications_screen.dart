import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  final _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getNotifications();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['isRead'] == true || item['id'] == null) return;
    try {
      await _api.markNotificationRead(item['id']!);
      if (mounted) setState(() => item['isRead'] = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    final text = dark ? Colors.white : AppColors.darkNavy;
    final card = dark ? AppColors.cardNavy : Colors.white;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
          title: const Text('Bildirimler'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Yenile',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 180),
                          Center(child: Text('Bildiriminiz bulunmuyor.'))
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final unread = item['isRead'] != true;
                            return Card(
                              color: card,
                              child: ListTile(
                                leading: Icon(
                                    unread
                                        ? Icons.notifications_active
                                        : Icons.notifications_none,
                                    color: unread
                                        ? AppColors.neonTurquoise
                                        : Colors.grey),
                                title: Text(
                                    item['title']?.toString() ?? 'Bildirim',
                                    style: TextStyle(
                                        color: text,
                                        fontWeight: unread
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                                subtitle: Text(
                                    item['message']?.toString() ?? '',
                                    style: TextStyle(
                                        color: text.withValues(alpha: .7))),
                                onTap: () => _markRead(item),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
