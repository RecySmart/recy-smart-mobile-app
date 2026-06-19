import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  });
  Future<AuthTokensModel> register({
    required String name,
    required String email,
    required String password,
  });
  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<AuthTokensModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.registerEndpoint,
        data: {'name': name, 'email': email, 'password': password},
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get(AppConstants.profileEndpoint);
      final data = response.data as Map<String, dynamic>;

      // Backend returns wallet for RECYCLER role.
      // If wallet is missing (user hasn't recycled yet), inject a zero wallet
      // so the UI doesn't break.
      if (data['role'] == 'RECYCLER' && data['wallet'] == null) {
        data['wallet'] = _emptyWallet(data['id'] as String? ?? '');
      }

      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// Returns a zeroed-out wallet map for new users who haven't recycled yet.
  Map<String, dynamic> _emptyWallet(String userId) => {
    'id': 'pending',
    'userId': userId,
    'currentBalance': 0,
    'lifetimeEarned': 0,
    'totalBottles': 0,
    'totalWeight': 0,
    'weight': 0.0,
    'co2Saved': 0.0,
    'level': null,
  };
}