import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/home_data.dart';
import '../repositories/home_repository.dart';

class GetHomeDataUseCase {
  final HomeRepository repository;
  GetHomeDataUseCase(this.repository);

  Future<Either<Failure, HomeData>> call() => repository.getHomeData();
}