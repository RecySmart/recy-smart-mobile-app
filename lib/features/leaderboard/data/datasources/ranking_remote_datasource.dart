import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/ranking.dart';
import '../models/ranking_model.dart';

abstract class RankingRemoteDataSource {
  Future<RankingModel> getRanking({
    required RankingPeriod period,
    required int page,
    required int limit,
  });
}

class RankingRemoteDataSourceImpl implements RankingRemoteDataSource {
  final ApiClient _apiClient;

  RankingRemoteDataSourceImpl(this._apiClient);

  @override
  Future<RankingModel> getRanking({
    required RankingPeriod period,
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConstants.rankingEndpoint,
        queryParameters: {
          'period': period.apiValue,
          'page': page,
          'limit': limit,
        },
      );
      return RankingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiClient.handleDioError(error);
    }
  }
}
