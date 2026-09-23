import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ranking.dart';
import '../repositories/ranking_repository.dart';

class GetRankingUseCase {
  final RankingRepository repository;

  GetRankingUseCase(this.repository);

  Future<Either<Failure, Ranking>> call({
    required RankingPeriod period,
    required int page,
    int limit = 20,
  }) {
    return repository.getRanking(period: period, page: page, limit: limit);
  }
}
