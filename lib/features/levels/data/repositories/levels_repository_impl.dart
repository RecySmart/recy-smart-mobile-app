import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/level.dart';
import '../../domain/repositories/levels_repository.dart';
import '../datasources/levels_remote_datasource.dart';

class LevelsRepositoryImpl implements LevelsRepository {
  final LevelsRemoteDataSource _remote;
  LevelsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<Level>>> getLevels() async {
    try {
      final levels = await _remote.getLevels();
      // Sort by minPointsRequired ascending
      levels.sort((a, b) => a.minPointsRequired.compareTo(b.minPointsRequired));
      return Right(levels);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}