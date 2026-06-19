import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/level.dart';
import '../repositories/levels_repository.dart';

class GetLevelsUseCase {
  final LevelsRepository repository;
  GetLevelsUseCase(this.repository);

  Future<Either<Failure, List<Level>>> call() => repository.getLevels();
}