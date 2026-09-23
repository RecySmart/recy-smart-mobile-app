import '../../domain/entities/ranking.dart';

class RankingEntryModel extends RankingEntry {
  const RankingEntryModel({
    required super.rank,
    required super.alias,
    required super.points,
    required super.isCurrentUser,
  });

  factory RankingEntryModel.fromJson(Map<String, dynamic> json) {
    return RankingEntryModel(
      rank: (json['rank'] as num).toInt(),
      alias: json['alias'] as String,
      points: (json['points'] as num).toInt(),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}

class RankingModel extends Ranking {
  const RankingModel({
    required super.period,
    required super.timezone,
    required super.startsAt,
    required super.endsAt,
    required super.page,
    required super.limit,
    required super.totalParticipants,
    required super.totalPages,
    required super.entries,
    required super.currentUser,
  });

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    final currentUserJson = json['currentUser'];
    return RankingModel(
      period: json['period'] == 'ALL_TIME'
          ? RankingPeriod.allTime
          : RankingPeriod.weekly,
      timezone: json['timezone'] as String? ?? 'America/Lima',
      startsAt: _parseDate(json['startsAt']),
      endsAt: _parseDate(json['endsAt']),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((entry) => RankingEntryModel.fromJson(
                entry as Map<String, dynamic>,
              ))
          .toList(),
      currentUser: currentUserJson is Map<String, dynamic>
          ? RankingEntryModel.fromJson(currentUserJson)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
