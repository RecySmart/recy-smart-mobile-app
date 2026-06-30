import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/app_notifications_bloc.dart';

/// Wraps the whole app. Listens to AppNotificationsBloc and renders a
/// floating banner whenever a new achievement or coupon validation arrives,
/// regardless of which screen the user is currently on.
class GlobalNotificationOverlay extends StatelessWidget {
  final Widget child;
  const GlobalNotificationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        BlocBuilder<AppNotificationsBloc, AppNotificationsState>(
          builder: (context, state) {
            final current = state.current;
            if (current == null) return const SizedBox.shrink();

            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _NotificationBanner(
                  key: ValueKey(current),
                  notification: current,
                  onDismiss: () => context
                      .read<AppNotificationsBloc>()
                      .add(AppNotificationsDismissEvent()),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationBanner extends StatefulWidget {
  final Object notification;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: _dismiss,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -200) _dismiss();
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif is AchievementNotification
                ? AppColors.primary
                : AppColors.secondary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: notif is AchievementNotification
              ? _AchievementContent(achievement: notif)
              : _CouponContent(
              coupon: notif as CouponValidatedNotification),
        ),
      ),
    );
  }
}

class _AchievementContent extends StatelessWidget {
  final AchievementNotification achievement;
  const _AchievementContent({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              achievement.iconEmoji ?? '🏆',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Logro desbloqueado!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                achievement.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                achievement.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CouponContent extends StatelessWidget {
  final CouponValidatedNotification coupon;
  const _CouponContent({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Cupón canjeado con éxito!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                coupon.rewardTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Validado en ${coupon.companyName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}