import 'package:flutter/material.dart';

import '../services/push_notification_service.dart';

class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({
    required this.icon,
    this.color,
    super.key,
  });

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PushNotificationService.instance.unreadCount,
      builder: (context, count, child) => Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(icon, color: color),
      ),
    );
  }
}
