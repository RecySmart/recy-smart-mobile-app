import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/recycling/presentation/pages/qr_scanner_page.dart';
import '../../features/recycling/presentation/pages/active_session_page.dart';
import '../../features/recycling/presentation/pages/session_summary_page.dart';
import '../../features/rewards/presentation/pages/rewards_store_page.dart';
import '../../features/rewards/presentation/pages/coupon_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/transaction_history_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/achievements_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router(AuthBloc authBloc) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      // Shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const MapPage(),
          ),
          GoRoute(
            path: AppRoutes.rewards,
            builder: (_, __) => const RewardsStorePage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (_, __) => const QrScannerPage(),
      ),
      GoRoute(
        path: AppRoutes.activeSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ActiveSessionPage(
            binId: extra['binId'] as String,
            locationName: extra['locationName'] as String,
            sessionId: extra['sessionId'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.sessionSummary,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SessionSummaryPage(
            bottlesDropped: extra['bottlesDropped'] as int,
            pointsEarned: extra['pointsEarned'] as int,
            co2Saved: extra['co2Saved'] as double,
            autoClosed: extra['autoClosed'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.couponDetail,
        builder: (context, state) {
          final couponId = state.pathParameters['id']!;
          return CouponDetailPage(couponId: couponId);
        },
      ),
      GoRoute(
        path: AppRoutes.transactionHistory,
        builder: (_, __) => const TransactionHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (_, __) => const AchievementsPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (_, __) => const LeaderboardPage(),
      ),
    ],
  );
}

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const map = '/map';
  static const rewards = '/rewards';
  static const profile = '/profile';
  static const qrScanner = '/scan';
  static const activeSession = '/session/active';
  static const sessionSummary = '/session/summary';
  static const couponDetail = '/coupons/:id';
  static const transactionHistory = '/profile/history';
  static const editProfile = '/profile/edit';
  static const achievements = '/profile/achievements';
  static const notifications = '/notifications';
  static const leaderboard = '/leaderboard';
}