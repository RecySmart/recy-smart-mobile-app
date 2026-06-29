import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static String baseApiUrl = 'https://vascular-habitat-correct.ngrok-free.dev';
  static String baseSocketURL =
      'https://vascular-habitat-correct.ngrok-free.dev';

  // --- API ---
  static String get baseUrl {
    if (kIsWeb) {
      return String.fromEnvironment('API_URL', defaultValue: baseApiUrl);
    }
    return Platform.isAndroid
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  // Socket URL — sin /api al final
  static String get socketUrl {
    if (kIsWeb) {
      return String.fromEnvironment(
        'SOCKET_URL',
        defaultValue: baseSocketURL,
      );
    }
    return Platform.isAndroid
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  // Auth endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String verifyEndpoint = '/auth/verify';
  static const String profileEndpoint = '/auth/profile';

  // Wallet endpoint
  static const String walletEndpoint = '/wallets/me';

  // Recycling / IoT endpoints
  static const String startSessionEndpoint = '/iot/bin/start/session';
  static const String endSessionEndpoint = '/iot/bin/end/session';

  // Gamification endpoints
  static const String activeRewardsEndpoint = '/rewards/active';
  static const String redeemCouponEndpoint = '/coupons/redeem';
  static const String myCouponsEndpoint = '/coupons';
  static const String transactionHistoryEndpoint = '/transactions/history';
  static const String myAchievementsEndpoint = '/achievements/my-badges';
  static const String levelsEndpoint = '/levels';

  // --- Secure Storage Keys ---
  static const String accessTokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';

  // --- SharedPrefs Keys ---
  static const String onboardingDoneKey = 'onboarding_done';

  // --- Session ---
  static const int pointsPerBottle = 10;
  static const int sessionAutoCloseSeconds = 60;
}
