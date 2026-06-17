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

  static const _notifications = [
    _Notification(
      title: 'Points Added Successfully!',
      body: 'You earned +30 points from your recent recycling session at Tambo - Carabayllo.',
      time: 'Just now',
      isNew: true,
      accentColor: AppColors.info,
      icon: Icons.monetization_on_rounded,
    ),
    _Notification(
      title: 'Session Auto-Closed',
      body: 'Your session was locked due to 60 seconds of inactivity. Your points were safely saved.',
      time: '10 mins ago',
      isNew: true,
      accentColor: AppColors.warning,
      icon: Icons.timer_off_rounded,
    ),
    _Notification(
      title: 'New Reward Available!',
      body: 'You now have enough points to redeem a Free Medium Coffee. Check the Rewards store!',
      time: 'Yesterday, 2:30 PM',
      isNew: false,
      accentColor: AppColors.primary,
      icon: Icons.card_giftcard_rounded,
    ),
    _Notification(
      title: 'Rank Up: Gold Recycler',
      body: "Congratulations! You've saved over 15kg of CO2 and reached the Gold tier.",
      time: 'Oct 12, 10:15 AM',
      isNew: false,
      accentColor: AppColors.tierGold,
      icon: Icons.emoji_events_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final newItems = _notifications.where((n) => n.isNew).toList();
    final earlierItems = _notifications.where((n) => !n.isNew).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (newItems.isNotEmpty) ...[
            _SectionHeader(label: 'NEW'),
            const SizedBox(height: 8),
            ...newItems.map((n) => _NotificationTile(notification: n)),
            const SizedBox(height: 16),
          ],
          if (earlierItems.isNotEmpty) ...[
            _SectionHeader(label: 'EARLIER'),
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
          backgroundColor: notification.accentColor.withOpacity(0.15),
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