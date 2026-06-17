// ── Profile Remote Datasource ────────────────────────────────────────────────
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';

class TransactionModel {
  final String id;
  final int amount;
  final String source;
  final String reference;
  final DateTime createdAt;
  final String? binLocation;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.source,
    required this.reference,
    required this.createdAt,
    this.binLocation,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      source: json['source'] as String,
      reference: json['reference'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      binLocation: json['binLocation'] as String?,
    );
  }
}

class AchievementModel {
  final String id;
  final String badgeName;
  final DateTime unlockedAt;

  const AchievementModel({
    required this.id,
    required this.badgeName,
    required this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      badgeName: json['badgeName'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
    );
  }
}

abstract class ProfileRemoteDataSource {
  Future<List<TransactionModel>> getTransactionHistory();
  Future<List<AchievementModel>> getAchievements();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;
  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<TransactionModel>> getTransactionHistory() async {
    try {
      final response = await _apiClient.get(AppConstants.transactionHistoryEndpoint);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  @override
  Future<List<AchievementModel>> getAchievements() async {
    try {
      final response = await _apiClient.get(AppConstants.myAchievementsEndpoint);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}