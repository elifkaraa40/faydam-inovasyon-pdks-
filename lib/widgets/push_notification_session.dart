import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_provider.dart';
import '../services/push_notification_service.dart';

class PushNotificationSession extends StatefulWidget {
  const PushNotificationSession({required this.child, super.key});

  final Widget child;

  @override
  State<PushNotificationSession> createState() =>
      _PushNotificationSessionState();
}

class _PushNotificationSessionState extends State<PushNotificationSession> {
  bool? _lastEnglish;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final english = context.watch<AppSettings>().isEnglish;
    if (_lastEnglish == english) return;
    _lastEnglish = english;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PushNotificationService.instance.activateForSession(
          context,
          english: english,
        );
      }
    });
  }

  @override
  void dispose() {
    PushNotificationService.instance.endSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
