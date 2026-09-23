import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ranking.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../datasources/ranking_remote_datasource.dart';

class RankingRepositoryImpl implements RankingRepository {
  final RankingRemoteDataSource _remote;

  RankingRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, Ranking>> getRanking({
    required RankingPeriod period,
    required int page,
    required int limit,
  }) async {
    try {
      return Right(
        await _remote.getRanking(period: period, page: page, limit: limit),
      );
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}
