import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/recycling_session_model.dart';

abstract class RecyclingRemoteDataSource {
  Future<RecyclingSessionModel> startSession({
    required String userId,
    required String smartBinId,
    required String qrToken,
    required double latitude,
    required double longitude,
  });

  Future<void> endSession(String sessionId);
}

class RecyclingRemoteDataSourceImpl implements RecyclingRemoteDataSource {
  final ApiClient _apiClient;
  RecyclingRemoteDataSourceImpl(this._apiClient);

  @override
  Future<RecyclingSessionModel> startSession({
    required String userId,
    required String smartBinId,
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.startSessionEndpoint,
        data: {
          'userId': userId,
          'smartBinId': smartBinId,
          'qrToken': qrToken,
          'userLocation': {
            'latitude': latitude,
            'longitude': longitude,
          },
        },
      );
      return RecyclingSessionModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<void> endSession(String sessionId) async {
    try {
      await _apiClient.post(
        AppConstants.endSessionEndpoint,
        data: {'sessionId': sessionId},
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}