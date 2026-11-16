import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../levels/data/datasources/levels_remote_datasource.dart';
import '../../../levels/domain/entities/level.dart';
import '../models/home_data_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeDataModel> getHomeData();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;
  final LevelsRemoteDataSource _levels;
  HomeRemoteDataSourceImpl(this._apiClient, this._levels);

  @override
  Future<HomeDataModel> getHomeData() async {
    try {
      final profileResponse = await _apiClient.get(AppConstants.profileEndpoint);
      final profileData = profileResponse.data as Map<String, dynamic>;

      final activity = _loadActivity();
      final levels = _loadLevels();
      return HomeDataModel.fromProfileAndTransactions(
        profileData,
        await activity,
        levels: await levels,
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  Future<Object?> _loadActivity() async {
    try {
      return (await _apiClient.get(AppConstants.transactionHistoryEndpoint)).data;
    } catch (_) {
      return [];
    }
  }

  Future<List<Level>> _loadLevels() async {
    try {
      return await _levels.getLevels();
    } catch (_) {
      return [];
    }
  }
}