import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/reward_model.dart';

abstract class RewardsRemoteDataSource {
  Future<List<RewardModel>> getActiveRewards();
  Future<UserCouponModel> redeemReward(String rewardId);
  Future<List<UserCouponModel>> getMyCoupons();
}

class RewardsRemoteDataSourceImpl implements RewardsRemoteDataSource {
  final ApiClient _apiClient;
  RewardsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<RewardModel>> getActiveRewards() async {
    try {
      final response = await _apiClient.get(AppConstants.activeRewardsEndpoint);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<UserCouponModel> redeemReward(String rewardId) async {
    try {
      final response = await _apiClient.post(
        AppConstants.redeemCouponEndpoint,
        data: {'rewardId': rewardId},
      );
      return UserCouponModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<List<UserCouponModel>> getMyCoupons() async {
    try {
      final response = await _apiClient.get(AppConstants.myCouponsEndpoint);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => UserCouponModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}