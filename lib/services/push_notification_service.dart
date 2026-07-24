import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../attendance_correction_screen.dart';
import '../izin_screen.dart';
import '../manager_main_screen.dart';
import '../notifications_screen.dart';
import '../work_location_screen.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase yapılandırılmadıysa uygulamanın arka plan süreci kapanmamalı.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  static const _storage = FlutterSecureStorage();
  static const _permissionPromptedKey = 'notification_permission_prompted';
  static const _platformChannel = MethodChannel('com.faydam.pdkspro/files');

  final unreadCount = ValueNotifier<int>(0);
  final permissionDenied = ValueNotifier<bool>(false);
  final changes = StreamController<void>.broadcast();
  final _seenEventIds = <String>{};
  final _knownNotificationIds = <String>{};
  final _api = ApiService();

  bool _available = false;
  bool _initialized = false;
  bool _activating = false;
  bool _english = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Timer? _pollTimer;
  bool _notificationBaselineLoaded = false;
  int _bannerSequence = 0;

  bool get isAvailable => _available;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _available = true;
      _messageSubscription =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleOpenedMessage(initial),
        );
      }
    } catch (_) {
      _available = false;
    }
  }

  Future<void> activateForSession(
    BuildContext context, {
    required bool english,
  }) async {
    if (_activating) return;
    _english = english;
    _activating = true;
    try {
      await _startPolling();
      if (!_available) {
        await refreshUnreadCount();
        return;
      }
      var settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        final prompted =
            await _storage.read(key: _permissionPromptedKey) == 'true';
        if (!prompted && context.mounted) {
          final allow = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: Text(english
                      ? 'Allow notifications'
                      : 'Bildirimlere izin ver'),
                  content: Text(english
                      ? 'Notification permission is required to receive instant updates about your leave, attendance, and account actions.'
                      : 'İzin, puantaj ve hesap işlemlerinizle ilgili anlık bildirimleri alabilmek için gereklidir.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(english ? 'Not now' : 'Şimdi değil'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(english ? 'Allow' : 'İzin ver'),
                    ),
                  ],
                ),
              ) ??
              false;
          await _storage.write(key: _permissionPromptedKey, value: 'true');
          if (allow) {
            settings = await FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
          }
        }
      }

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      permissionDenied.value = !authorized;
      if (authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) await _registerToken(token);
      }
      await refreshUnreadCount();
    } catch (_) {
      // Push kurulumu ana oturum akışını başarısız hale getirmemelidir.
    } finally {
      _activating = false;
    }
  }

  Future<void> refreshUnreadCount() async {
    if (!await _api.hasSession()) {
      unreadCount.value = 0;
      return;
    }
    try {
      unreadCount.value = await _api.getUnreadNotificationCount();
    } catch (_) {}
  }

  Future<void> _startPolling() async {
    if (_pollTimer != null) return;
    await _pollNotifications();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _pollNotifications(),
    );
  }

  Future<void> _pollNotifications() async {
    if (!await _api.hasSession()) return;
    try {
      final items = await _api.getNotifications(
        language: _english ? 'en' : 'tr',
      );
      final unread = items.where((item) => item['isRead'] != true).toList();
      unreadCount.value = unread.length;
      final newItems = _notificationBaselineLoaded
          ? unread
              .where((item) =>
                  item['id'] != null &&
                  !_knownNotificationIds.contains(item['id'].toString()))
              .toList()
          : const <Map<String, dynamic>>[];
      _knownNotificationIds
        ..clear()
        ..addAll(items
            .where((item) => item['id'] != null)
            .map((item) => item['id'].toString()));
      _notificationBaselineLoaded = true;
      if (newItems.isNotEmpty) {
        final item = newItems.first;
        _showBanner(
          title: item['title']?.toString() ??
              (_english ? 'New notification' : 'Yeni bildirim'),
          body: item['message']?.toString() ?? '',
          route: routeForType(item['type']?.toString()),
        );
        changes.add(null);
      }
    } catch (_) {}
  }

  Future<void> openNotificationSettings() async {
    try {
      await _platformChannel.invokeMethod<void>('openNotificationSettings');
    } catch (_) {}
  }

  Future<void> _registerToken(String token) async {
    if (!await _api.hasSession()) return;
    try {
      await _api.registerPushDevice(
        token: token,
        language: _english ? 'en' : 'tr',
      );
    } catch (_) {
      // Token yenileme sonraki uygulama açılışında yeniden denenecektir.
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final eventId = message.data['eventId'] ?? message.messageId;
    if (eventId != null && !_seenEventIds.add(eventId)) return;
    if (eventId != null) _knownNotificationIds.add(eventId);
    unreadCount.value++;
    changes.add(null);

    final notification = message.notification;
    final title = notification?.title ??
        message.data['title'] ??
        (_english ? 'New notification' : 'Yeni bildirim');
    final body = notification?.body ?? message.data['message'] ?? '';
    _showBanner(
      title: title,
      body: body,
      route: message.data['route']?.toString() ?? 'notifications',
    );
  }

  void _showBanner({
    required String title,
    required String body,
    required String route,
  }) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final sequence = ++_bannerSequence;
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          leading: const Icon(Icons.notifications_active_outlined),
          content: Text('$title${body.isEmpty ? '' : '\n$body'}'),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                navigateRoute(route);
              },
              child: Text(_english ? 'View' : 'Görüntüle'),
            ),
            IconButton(
              tooltip: _english ? 'Close' : 'Kapat',
              onPressed: messenger.hideCurrentMaterialBanner,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
    Future<void>.delayed(const Duration(seconds: 7), () {
      if (_bannerSequence == sequence) messenger.hideCurrentMaterialBanner();
    });
  }

  void _handleOpenedMessage(RemoteMessage message) =>
      navigateFromData(message.data);

  void navigateForType(Object? type) =>
      navigateRoute(routeForType(type?.toString()));

  String routeForType(String? type) {
    switch (type) {
      case 'LeaveApproved':
      case 'LeaveRejected':
        return 'leave_requests';
      case 'AttendanceCorrectionApproved':
      case 'AttendanceCorrectionRejected':
        return 'attendance_corrections';
      case 'WorkLocationAssigned':
      case 'FieldWorkRequestApproved':
      case 'FieldWorkRequestRejected':
        return 'work_locations';
      case 'LeaveRequestCreated':
      case 'AttendanceCorrectionCreated':
      case 'FieldWorkRequestCreated':
      case 'RegistrationApprovalRequested':
        return 'manager_approvals';
      default:
        return 'notifications';
    }
  }

  void navigateFromData(Map<String, dynamic> data) =>
      navigateRoute(data['route']?.toString() ?? 'notifications');

  void navigateRoute(String route) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    final Widget destination = switch (route) {
      'leave_requests' => const IzinScreen(),
      'attendance_corrections' => const AttendanceCorrectionScreen(),
      'work_locations' => const WorkLocationScreen(),
      'manager_approvals' => const ManagerMainScreen(initialIndex: 1),
      _ => const NotificationsScreen(),
    };
    navigator.push(MaterialPageRoute(builder: (_) => destination));
  }

  void endSession() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _notificationBaselineLoaded = false;
    _knownNotificationIds.clear();
    _seenEventIds.clear();
    unreadCount.value = 0;
  }

  void dispose() {
    endSession();
    _tokenSubscription?.cancel();
    _messageSubscription?.cancel();
    _openedSubscription?.cancel();
    changes.close();
    unreadCount.dispose();
    permissionDenied.dispose();
  }
}

final appNavigatorKey = GlobalKey<NavigatorState>();
final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
