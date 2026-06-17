import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/smart_bin.dart';
import '../repositories/map_repository.dart';

class GetAllBinsUseCase {
  final MapRepository repository;
  GetAllBinsUseCase(this.repository);

  Future<Either<Failure, List<SmartBin>>> call() => repository.getAllBins();
}