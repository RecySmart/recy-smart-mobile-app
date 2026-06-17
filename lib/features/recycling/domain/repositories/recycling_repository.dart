import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recycling_session.dart';

abstract class RecyclingRepository {
  Future<Either<Failure, RecyclingSession>> startSession(String binId);
}