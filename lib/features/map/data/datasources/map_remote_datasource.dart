import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/smart_bin_model.dart';

abstract class MapRemoteDataSource {
  Future<List<SmartBinModel>> getAllBins();
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final ApiClient _apiClient;
  MapRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<SmartBinModel>> getAllBins() async {
    try {
      final response = await _apiClient.get('/admin/bins');
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => SmartBinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final failure = ApiClient.handleDioError(e);
      // If endpoint not yet implemented, use mock data
      if (failure is NotFoundFailure || failure is ServerFailure) {
        return SmartBinModel.mockBins;
      }
      throw failure;
    } catch (_) {
      // Fallback to mock when backend patch not applied yet
      return SmartBinModel.mockBins;
    }
  }
}