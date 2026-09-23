import 'package:flutter_test/flutter_test.dart';
import 'package:recysmart/features/leaderboard/data/models/ranking_model.dart';
import 'package:recysmart/features/leaderboard/domain/entities/ranking.dart';

void main() {
  test('parses the anonymous paginated ranking contract', () {
    final ranking = RankingModel.fromJson(const {
      'period': 'WEEKLY',
      'timezone': 'America/Lima',
      'startsAt': '2026-09-14T05:00:00.000Z',
      'endsAt': '2026-09-21T05:00:00.000Z',
      'page': 1,
      'limit': 20,
      'totalParticipants': 1,
      'totalPages': 1,
      'entries': [
        {
          'rank': 1,
          'alias': 'Recycler A7F2',
          'points': 120,
          'isCurrentUser': true,
        },
      ],
      'currentUser': {
        'rank': 1,
        'alias': 'Recycler A7F2',
        'points': 120,
        'isCurrentUser': true,
      },
    });

    expect(ranking.period, RankingPeriod.weekly);
    expect(ranking.entries.single.alias, 'Recycler A7F2');
    expect(ranking.currentUser?.rank, 1);
    expect(ranking.startsAt, DateTime.parse('2026-09-14T05:00:00.000Z'));
  });
}
