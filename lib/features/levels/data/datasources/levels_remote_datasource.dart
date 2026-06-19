import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/level_model.dart';

abstract class LevelsRemoteDataSource {
  Future<List<LevelModel>> getLevels();
}

class LevelsRemoteDataSourceImpl implements LevelsRemoteDataSource {
  final ApiClient _apiClient;
  LevelsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<LevelModel>> getLevels() async {
    try {
      final response = await _apiClient.get(AppConstants.levelsEndpoint);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => LevelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}