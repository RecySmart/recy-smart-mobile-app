import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/recycling_session_model.dart';

abstract class RecyclingRemoteDataSource {
  Future<RecyclingSessionModel> startSession(String binId);
}

class RecyclingRemoteDataSourceImpl implements RecyclingRemoteDataSource {
  final ApiClient _apiClient;
  RecyclingRemoteDataSourceImpl(this._apiClient);

  @override
  Future<RecyclingSessionModel> startSession(String binId) async {
    try {
      final response = await _apiClient.post(
        AppConstants.startSessionEndpoint,
        data: {'binId': binId},
      );
      return RecyclingSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}