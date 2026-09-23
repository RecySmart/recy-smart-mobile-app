import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class _Notification {
  final String title;
  final String body;
  final String time;
  final bool isNew;
  final Color accentColor;
  final IconData icon;

  const _Notification({
    required this.title,
    required this.body,
    required this.time,
    required this.isNew,
    required this.accentColor,
    required this.icon,
  });
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const List<_Notification> _notifications = [];

  @override
  Widget build(BuildContext context) {
    final newItems = _notifications.where((n) => n.isNew).toList();
    final earlierItems = _notifications.where((n) => !n.isNew).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (_notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text('No hay notificaciones disponibles.'),
              ),
            ),
          if (newItems.isNotEmpty) ...[
            const _SectionHeader(label: 'NUEVO'),
            const SizedBox(height: 8),
            ...newItems.map((n) => _NotificationTile(notification: n)),
            const SizedBox(height: 16),
          ],
          if (earlierItems.isNotEmpty) ...[
            const _SectionHeader(label: 'ANTERIORES'),
            const SizedBox(height: 8),
            ...earlierItems.map((n) => _NotificationTile(notification: n)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        letterSpacing: 1.5,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _Notification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notification.isNew
            ? const Color(0xFFF0F4FF)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: notification.isNew
            ? Border(
          left: BorderSide(
            color: notification.accentColor,
            width: 3,
          ),
        )
            : null,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: notification.accentColor.withValues(alpha: 0.15),
          child: Icon(notification.icon,
              color: notification.accentColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (notification.isNew)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              notification.time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
