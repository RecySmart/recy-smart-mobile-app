import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/level.dart';

abstract class LevelsRepository {
  Future<Either<Failure, List<Level>>> getLevels();
}