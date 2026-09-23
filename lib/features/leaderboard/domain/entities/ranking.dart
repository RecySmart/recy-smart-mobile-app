import 'package:equatable/equatable.dart';

enum RankingPeriod { weekly, allTime }

extension RankingPeriodValue on RankingPeriod {
  String get apiValue => this == RankingPeriod.weekly ? 'WEEKLY' : 'ALL_TIME';
  String get label =>
      this == RankingPeriod.weekly ? 'Esta semana' : 'Histórico';
}

class RankingEntry extends Equatable {
  final int rank;
  final String alias;
  final int points;
  final bool isCurrentUser;

  const RankingEntry({
    required this.rank,
    required this.alias,
    required this.points,
    required this.isCurrentUser,
  });

  @override
  List<Object> get props => [rank, alias, points, isCurrentUser];
}

class Ranking extends Equatable {
  final RankingPeriod period;
  final String timezone;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int page;
  final int limit;
  final int totalParticipants;
  final int totalPages;
  final List<RankingEntry> entries;
  final RankingEntry? currentUser;

  const Ranking({
    required this.period,
    required this.timezone,
    required this.startsAt,
    required this.endsAt,
    required this.page,
    required this.limit,
    required this.totalParticipants,
    required this.totalPages,
    required this.entries,
    required this.currentUser,
  });

  @override
  List<Object?> get props => [
        period,
        timezone,
        startsAt,
        endsAt,
        page,
        limit,
        totalParticipants,
        totalPages,
        entries,
        currentUser,
      ];
}
