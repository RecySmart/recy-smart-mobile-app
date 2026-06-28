import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recycling_session.dart';

abstract class RecyclingRepository {
  Future<Either<Failure, RecyclingSession>> startSession({
    required String userId,
    required String smartBinId,
    required String qrToken,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, void>> endSession(String sessionId);
}