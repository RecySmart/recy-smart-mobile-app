import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
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

  Future<RecyclingSessionModel> startManualSession({
    required String qrToken,
    required double latitude,
    required double longitude,
  });

  Future<void> endSession(String sessionId);
  Future<RecyclingSessionSnapshotModel> getSessionStatus(String sessionId);
  Future<RecyclingSessionSnapshotModel?> getActiveSession();
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
  Future<RecyclingSessionModel> startManualSession({
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.startManualSessionEndpoint,
        data: {
          'qrToken': qrToken,
          'userLocation': {'latitude': latitude, 'longitude': longitude},
        },
      );
      return RecyclingSessionModel.fromJson(response.data as Map<String, dynamic>);
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

  @override
  Future<RecyclingSessionSnapshotModel?> getActiveSession() async {
    try {
      final response = await _apiClient.get(AppConstants.activeSessionEndpoint);
      final body = response.data as Map<String, dynamic>;
      if (!body.containsKey('session')) {
        throw const FormatException('Missing active session response');
      }
      final session = body['session'] as Map<String, dynamic>?;
      return session == null
          ? null
          : RecyclingSessionSnapshotModel.fromJson(session);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<RecyclingSessionSnapshotModel> getSessionStatus(String sessionId) async {
    try {
      final response = await _apiClient.get(
        '${AppConstants.sessionStatusEndpoint}/$sessionId',
      );
      return RecyclingSessionSnapshotModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
