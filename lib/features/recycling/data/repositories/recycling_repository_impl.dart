import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../datasources/recycling_remote_datasource.dart';

class RecyclingRepositoryImpl implements RecyclingRepository {
  final RecyclingRemoteDataSource _remote;
  RecyclingRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, RecyclingSession>> startSession(String binId) async {
    try {
      final session = await _remote.startSession(binId);
      return Right(session);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}