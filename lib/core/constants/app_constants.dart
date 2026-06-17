class AppConstants {
  AppConstants._();

  // --- API ---
  // static const String baseUrl = 'http://localhost:3000/api';

  // Local
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Auth endpoints
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String verifyEndpoint = '/auth/verify';
  static const String profileEndpoint = '/auth/profile';

  // Recycling endpoints
  static const String startSessionEndpoint = '/iot/bin/start/session';

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

  // --- Points per bottle ---
  static const int pointsPerBottle = 10;

  // --- Session timeout in seconds ---
  static const int sessionAutoCloseSeconds = 60;
}