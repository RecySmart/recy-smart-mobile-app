import 'package:equatable/equatable.dart';
import '../../../levels/domain/entities/level.dart';

class HomeData extends Equatable {
  final int totalPoints;
  final int totalBottles;
  final double co2Saved;
  final List<RecentActivity> recentActivity;
  final HomeLevelProgress? levelProgress;

  const HomeData({
    required this.totalPoints,
    required this.totalBottles,
    required this.co2Saved,
    required this.recentActivity,
    this.levelProgress,
  });

  @override
  List<Object?> get props =>
      [totalPoints, totalBottles, co2Saved, recentActivity, levelProgress];
}

class HomeLevelProgress extends Equatable {
  final int lifetimeEarned;
  final Level current;
  final Level? next;

  const HomeLevelProgress._(this.lifetimeEarned, this.current, this.next);

  static HomeLevelProgress? fromLevels(int? lifetimeEarned, List<Level> levels) {
    if (lifetimeEarned == null || levels.isEmpty) return null;
    final sorted = [...levels]
      ..sort((a, b) => a.minPointsRequired.compareTo(b.minPointsRequired));
    Level? current;
    for (final level in sorted) {
      if (lifetimeEarned < level.minPointsRequired) {
        return current == null
            ? null
            : HomeLevelProgress._(lifetimeEarned, current, level);
      }
      current = level;
    }
    return HomeLevelProgress._(lifetimeEarned, current!, null);
  }

  int get pointsRemaining => next == null ? 0 : next!.minPointsRequired - lifetimeEarned;

  double get fraction {
    final target = next;
    if (target == null) return 1;
    final floor = current.minPointsRequired;
    return ((lifetimeEarned - floor) / (target.minPointsRequired - floor))
        .clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [lifetimeEarned, current, next];
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