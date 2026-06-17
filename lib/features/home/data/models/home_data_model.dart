import '../../domain/entities/home_data.dart';

class RecentActivityModel extends RecentActivity {
  const RecentActivityModel({
    required super.id,
    required super.type,
    required super.locationName,
    required super.pointsDelta,
    super.bottleCount,
    required super.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as num?)?.toInt() ??
        (json['pointsDelta'] as num?)?.toInt() ??
        0;
    final type = json['type'] as String? ?? 'DEPOSIT';

    return RecentActivityModel(
      id: json['id'] as String,
      type: type,
      locationName: json['binLocation'] as String? ??
          json['locationName'] as String? ??
          json['description'] as String? ??
          'RecySmart Bin',
      pointsDelta: type == 'REDEEM' ? -points.abs() : points,
      bottleCount: (json['bottleCount'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class HomeDataModel extends HomeData {
  const HomeDataModel({
    required super.totalPoints,
    required super.totalBottles,
    required super.co2Saved,
    required super.pointsToNextReward,
    required super.recentActivity,
    super.levelName,
  });

  factory HomeDataModel.fromProfileAndTransactions(
      Map<String, dynamic> profile,
      dynamic txData,
      ) {
    final wallet = profile['wallet'] as Map<String, dynamic>? ?? {};
    final currentBalance = (wallet['currentBalance'] as num?)?.toInt() ?? 0;
    final totalBottles = (wallet['totalBottles'] as num?)?.toInt() ?? 0;
    final totalWeight = (wallet['totalWeight'] as num?)?.toDouble() ?? 0.0;
    final co2Saved = (wallet['co2Saved'] as num?)?.toDouble() ?? totalWeight * 1.5;
    final level = wallet['level'] as Map<String, dynamic>?;
    final levelName = level?['name'] as String?;

    List<RecentActivityModel> activities = [];
    if (txData is List) {
      activities = txData
          .take(5)
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (txData is Map && txData['data'] is List) {
      activities = (txData['data'] as List)
          .take(5)
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 500 pts is the minimum reward threshold
    const nextRewardThreshold = 500;
    final pointsToNext = currentBalance >= nextRewardThreshold
        ? 0
        : nextRewardThreshold - currentBalance;

    return HomeDataModel(
      totalPoints: currentBalance,
      totalBottles: totalBottles,
      co2Saved: co2Saved,
      pointsToNextReward: pointsToNext,
      recentActivity: activities,
      levelName: levelName,
    );
  }
}