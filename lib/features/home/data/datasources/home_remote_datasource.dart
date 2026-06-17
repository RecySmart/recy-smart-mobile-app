import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/home_data_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeDataModel> getHomeData();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;
  HomeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<HomeDataModel> getHomeData() async {
    try {
      // Only fetch profile — skip transactions to avoid 500 if gamification-ms is down
      final profileResponse = await _apiClient.get(AppConstants.profileEndpoint);
      final profileData = profileResponse.data as Map<String, dynamic>;

      // Try transactions separately — if it fails, use empty list
      dynamic txData = [];
      try {
        final txResponse = await _apiClient.get(
          AppConstants.transactionHistoryEndpoint,
        );
        txData = txResponse.data;
      } catch (_) {
        // gamification-ms may not be running — show empty activity
        txData = [];
      }

      return HomeDataModel.fromProfileAndTransactions(profileData, txData);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}