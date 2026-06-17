import 'package:equatable/equatable.dart';

class HomeData extends Equatable {
  final int totalPoints;
  final int totalBottles;
  final double co2Saved;
  final int pointsToNextReward;
  final List<RecentActivity> recentActivity;
  final String? levelName;

  const HomeData({
    required this.totalPoints,
    required this.totalBottles,
    required this.co2Saved,
    required this.pointsToNextReward,
    required this.recentActivity,
    this.levelName,
  });

  @override
  List<Object?> get props => [totalPoints, totalBottles, co2Saved, recentActivity, levelName];
}

class RecentActivity extends Equatable {
  final String id;
  final String type; // 'DEPOSIT' | 'REDEEM'
  final String locationName;
  final int pointsDelta;
  final int? bottleCount;
  final DateTime createdAt;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.locationName,
    required this.pointsDelta,
    this.bottleCount,
    required this.createdAt,
  });

  bool get isDeposit => type == 'DEPOSIT';

  @override
  List<Object?> get props => [id, type, locationName, pointsDelta, bottleCount, createdAt];
}