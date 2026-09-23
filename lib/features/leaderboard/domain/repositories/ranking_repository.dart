import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ranking.dart';

abstract class RankingRepository {
  Future<Either<Failure, Ranking>> getRanking({
    required RankingPeriod period,
    required int page,
    required int limit,
  });
}
