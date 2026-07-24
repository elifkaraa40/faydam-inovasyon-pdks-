import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';

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
  Timer? _refreshTimer;
  StreamSubscription<void>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(showLoading: false),
    );
    _pushSubscription = PushNotificationService.instance.changes.stream.listen(
      (_) => _load(showLoading: false),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushNotificationService.instance.activateForSession(
        context,
        english: context.read<AppSettings>().isEnglish,
      );
      _load(showLoading: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _pushSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _api.getNotifications(
        language: context.read<AppSettings>().isEnglish ? 'en' : 'tr',
      );
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
        PushNotificationService.instance.unreadCount.value =
            items.where((item) => item['isRead'] != true).length;
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['id'] == null) return;
    try {
      if (item['isRead'] != true) {
        await _api.markNotificationRead(item['id']!);
        if (mounted) setState(() => item['isRead'] = true);
        await PushNotificationService.instance.refreshUnreadCount();
      }
      if (mounted) {
        PushNotificationService.instance.navigateForType(item['type']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    final en = context.watch<AppSettings>().isEnglish;
    final text = dark ? Colors.white : AppColors.darkNavy;
    final card = dark ? AppColors.cardNavy : Colors.white;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
          title: Text(en ? 'Notifications' : 'Bildirimler'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: en ? 'Refresh' : 'Yenile',
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
              : Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          PushNotificationService.instance.permissionDenied,
                      builder: (context, denied, child) => denied
                          ? Material(
                              color: Colors.orange.withValues(alpha: .16),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.notifications_off_outlined,
                                  color: Colors.orange,
                                ),
                                title: Text(en
                                    ? 'System notifications are disabled'
                                    : 'Sistem bildirimleri kapalı'),
                                subtitle: Text(en
                                    ? 'Enable notifications in device settings to receive instant updates.'
                                    : 'Anlık bildirim almak için cihaz ayarlarından izin verebilirsiniz.'),
                                trailing: TextButton(
                                  onPressed: PushNotificationService
                                      .instance.openNotificationSettings,
                                  child: Text(en ? 'Settings' : 'Ayarlar'),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(children: [
                                const SizedBox(height: 180),
                                Center(
                                  child: Text(en
                                      ? 'You have no notifications.'
                                      : 'Bildiriminiz bulunmuyor.'),
                                ),
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
                                          item['title']?.toString() ??
                                              'Bildirim',
                                          style: TextStyle(
                                              color: text,
                                              fontWeight: unread
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                      subtitle: Text(
                                          item['message']?.toString() ?? '',
                                          style: TextStyle(
                                              color:
                                                  text.withValues(alpha: .7))),
                                      onTap: () => _markRead(item),
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
