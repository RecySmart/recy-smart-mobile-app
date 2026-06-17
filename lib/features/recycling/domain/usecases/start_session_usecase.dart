import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

class StartSessionUseCase {
  final RecyclingRepository repository;
  StartSessionUseCase(this.repository);

  Future<Either<Failure, RecyclingSession>> call(String binId) =>
      repository.startSession(binId);
}