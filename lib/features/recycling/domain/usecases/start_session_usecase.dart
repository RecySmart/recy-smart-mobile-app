import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

class StartSessionUseCase {
  final RecyclingRepository repository;
  StartSessionUseCase(this.repository);

  Future<Either<Failure, RecyclingSession>> call({
    required String userId,
    required String smartBinId,
    required String qrToken,
    required double latitude,
    required double longitude,
  }) =>
      repository.startSession(
        userId: userId,
        smartBinId: smartBinId,
        qrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
      );
}

class EndSessionUseCase {
  final RecyclingRepository repository;
  EndSessionUseCase(this.repository);

  Future<Either<Failure, void>> call(String sessionId) =>
      repository.endSession(sessionId);
}