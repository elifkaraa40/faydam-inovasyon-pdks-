import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'services/api_service.dart';
import 'widgets/notification_badge_icon.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  late int _selectedIndex = widget.initialIndex.clamp(0, 3);

  late final List<Widget> _screens = const [
    _ManagerDashboardScreen(),
    _ManagerApprovalsScreen(),
    _ManagerPersonnelScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (value) => setState(() => _selectedIndex = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Özet',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_seal_fill),
            label: 'Onaylar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2_fill),
            label: 'Personel',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill),
            label: 'Profilim',
          ),
        ],
      ),
    );
  }
}

abstract final class _ManagerUi {
  static Color background(bool dark) =>
      dark ? AppColors.darkNavy : AppColors.lightBackground;
  static Color card(bool dark) => dark ? AppColors.cardNavy : Colors.white;
  static Color text(bool dark) => dark ? Colors.white : AppColors.darkNavy;
  static Color secondary(bool dark) =>
      dark ? Colors.grey.shade400 : Colors.grey.shade600;
}

class _ManagerDashboardScreen extends StatefulWidget {
  const _ManagerDashboardScreen();

  @override
  State<_ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<_ManagerDashboardScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future = _api.getManagerDashboard();

  Future<void> _reload() async {
    final future = _api.getManagerDashboard();
    setState(() => _future = future);
    await future;
  }

  int _number(Map<String, dynamic> data, String key) =>
      (data[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final dark = settings.isDarkMode;
    return Scaffold(
      backgroundColor: _ManagerUi.background(dark),
      appBar: AppBar(
        title: const Text('Yönetici Özeti'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            icon: const NotificationBadgeIcon(
              icon: Icons.notifications_outlined,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error, onRetry: _reload);
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final pending = data['pendingApprovals'] is Map
              ? Map<String, dynamic>.from(data['pendingApprovals'] as Map)
              : const <String, dynamic>{};
          final pendingTotal = pending.values
              .whereType<num>()
              .fold<int>(0, (sum, value) => sum + value.toInt());
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Hoş geldiniz, ${settings.userName ?? 'Yönetici'}',
                  style: TextStyle(
                    color: _ManagerUi.text(dark),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _MetricGrid(
                  dark: dark,
                  metrics: [
                    ('Bekleyen Onay', pendingTotal, Icons.pending_actions),
                    ('Giriş Yapan', _number(data, 'enteredToday'), Icons.login),
                    ('Çıkış Yapan', _number(data, 'exitedToday'), Icons.logout),
                    (
                      'Eksik Kayıt',
                      _number(data, 'missingAttendance'),
                      Icons.warning_amber
                    ),
                    (
                      'Ofiste',
                      _number(data, 'officePersonnel'),
                      Icons.apartment
                    ),
                    (
                      'Sahada',
                      _number(data, 'fieldPersonnel'),
                      Icons.location_on_outlined
                    ),
                    (
                      'Uzaktan',
                      _number(data, 'remotePersonnel'),
                      Icons.home_work_outlined
                    ),
                    (
                      'Molada',
                      _number(data, 'personnelOnBreak'),
                      Icons.free_breakfast_outlined
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ManagerApprovalsScreen extends StatefulWidget {
  const _ManagerApprovalsScreen();

  @override
  State<_ManagerApprovalsScreen> createState() =>
      _ManagerApprovalsScreenState();
}

class _ManagerApprovalsScreenState extends State<_ManagerApprovalsScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future = _api.getManagerApprovalsSummary();

  Future<void> _reload() async {
    final future = _api.getManagerApprovalsSummary();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    return Scaffold(
      backgroundColor: _ManagerUi.background(dark),
      appBar: AppBar(
        title: const Text('Bekleyen Onaylar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error, onRetry: _reload);
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final items = [
            ('Kayıt Başvuruları', 'registrations', Icons.person_add_alt_1),
            ('İzin Talepleri', 'leaveRequests', Icons.event_available),
            (
              'Puantaj Düzeltmeleri',
              'attendanceCorrections',
              Icons.edit_calendar
            ),
            (
              'Çalışma Konumu',
              'workLocationRequests',
              Icons.location_on_outlined
            ),
          ];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final count = (data[item.$2] as num?)?.toInt() ?? 0;
                return Card(
                  color: _ManagerUi.card(dark),
                  child: ListTile(
                    leading: Icon(item.$3, color: AppColors.neonTurquoise),
                    title: Text(item.$1,
                        style: TextStyle(color: _ManagerUi.text(dark))),
                    trailing: CircleAvatar(
                      backgroundColor: AppColors.neonTurquoise,
                      child: Text('$count',
                          style: const TextStyle(
                              color: AppColors.darkNavy,
                              fontWeight: FontWeight.bold)),
                    ),
                    onTap: count == 0
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _ManagerApprovalListScreen(
                                  title: item.$1,
                                  kind: item.$2 == 'registrations'
                                      ? 'registrations'
                                      : item.$2 == 'leaveRequests'
                                          ? 'leave-requests'
                                          : item.$2 == 'attendanceCorrections'
                                              ? 'attendance-corrections'
                                              : 'work-location-requests',
                                ),
                              ),
                            ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ManagerPersonnelScreen extends StatefulWidget {
  const _ManagerPersonnelScreen();

  @override
  State<_ManagerPersonnelScreen> createState() =>
      _ManagerPersonnelScreenState();
}

class _ManagerPersonnelScreenState extends State<_ManagerPersonnelScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future = _api.getManagerPersonnelStatus();

  Future<void> _reload() async {
    final future = _api.getManagerPersonnelStatus();
    setState(() => _future = future);
    await future;
  }

  String _time(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    return Scaffold(
      backgroundColor: _ManagerUi.background(dark),
      appBar: AppBar(
        title: const Text('Personel Durumları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error, onRetry: _reload);
          }
          final rawItems = snapshot.data?['items'];
          final items = rawItems is List
              ? rawItems
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Gösterilecek personel bulunmuyor.'))
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final onBreak = item['isOnBreak'] == true;
                      final missing = item['missingRecord'] == true;
                      final statusColor = missing
                          ? Colors.redAccent
                          : onBreak
                              ? Colors.orangeAccent
                              : Colors.greenAccent;
                      return Card(
                        color: _ManagerUi.card(dark),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: .15),
                            child: Icon(Icons.person, color: statusColor),
                          ),
                          title: Text(
                              item['fullName']?.toString() ?? 'Personel',
                              style: TextStyle(
                                  color: _ManagerUi.text(dark),
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${item['department'] ?? 'Departman yok'} • ${item['workLocation'] ?? 'Konum yok'}\nGiriş ${_time(item['firstEntry'])}  Çıkış ${_time(item['lastExit'])}',
                            style: TextStyle(color: _ManagerUi.secondary(dark)),
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            onBreak
                                ? 'Molada'
                                : item['attendanceStatus']?.toString() ?? '—',
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _ManagerApprovalListScreen extends StatefulWidget {
  const _ManagerApprovalListScreen({required this.title, required this.kind});
  final String title;
  final String kind;

  @override
  State<_ManagerApprovalListScreen> createState() =>
      _ManagerApprovalListScreenState();
}

class _ManagerApprovalListScreenState
    extends State<_ManagerApprovalListScreen> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future =
      _api.getManagerApprovalItems(widget.kind);

  Future<void> _reload() async {
    final future = _api.getManagerApprovalItems(widget.kind);
    setState(() => _future = future);
    await future;
  }

  Future<void> _review(Map<String, dynamic> item, bool approve) async {
    final id = item['id'];
    if (id == null) return;
    try {
      await _api.reviewManagerItem(
        kind: widget.kind,
        id: id,
        approve: approve,
      );
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _title(Map<String, dynamic> item) =>
      item['fullName']?.toString() ??
      item['employeeName']?.toString() ??
      item['reason']?.toString() ??
      'Onay talebi';

  String _subtitle(Map<String, dynamic> item) {
    final date = item['workDate'] ?? item['startDate'] ?? item['createdAt'];
    final reason = item['reason']?.toString();
    return [date?.toString(), reason]
        .whereType<String>()
        .where((x) => x.isNotEmpty)
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppSettings>().isDarkMode;
    final text = _ManagerUi.text(dark);
    return Scaffold(
      backgroundColor: _ManagerUi.background(dark),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error, onRetry: _reload);
          }
          final raw = snapshot.data?['items'];
          final items = raw is List
              ? raw
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Bekleyen kayıt bulunmuyor.'))
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        color: _ManagerUi.card(dark),
                        child: ListTile(
                          title: Text(_title(item),
                              style: TextStyle(
                                  color: text, fontWeight: FontWeight.bold)),
                          subtitle: Text(_subtitle(item),
                              style:
                                  TextStyle(color: _ManagerUi.secondary(dark))),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              IconButton(
                                tooltip: 'Reddet',
                                onPressed: () => _review(item, false),
                                icon: const Icon(Icons.close,
                                    color: Colors.redAccent),
                              ),
                              IconButton(
                                tooltip: 'Onayla',
                                onPressed: () => _review(item, true),
                                icon: const Icon(Icons.check,
                                    color: Colors.greenAccent),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.dark, required this.metrics});
  final bool dark;
  final List<(String, int, IconData)> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _ManagerUi.card(dark),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(metric.$3, color: AppColors.neonTurquoise),
              Text('${metric.$2}',
                  style: TextStyle(
                      color: _ManagerUi.text(dark),
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              Text(metric.$1,
                  style: TextStyle(
                      color: _ManagerUi.secondary(dark), fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}
