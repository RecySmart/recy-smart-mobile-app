import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../datasources/recycling_remote_datasource.dart';

class RecyclingRepositoryImpl implements RecyclingRepository {
  final RecyclingRemoteDataSource _remote;
  RecyclingRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, RecyclingSession>> startSession({
    required String userId,
    required String smartBinId,
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final session = await _remote.startSession(
        userId: userId,
        smartBinId: smartBinId,
        qrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(session);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endSession(String sessionId) async {
    try {
      await _remote.endSession(sessionId);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}