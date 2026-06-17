import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/profile_remote_datasource.dart';

class GetTransactionHistoryUseCase {
  final ProfileRepository repository;
  GetTransactionHistoryUseCase(this.repository);
  Future<Either<Failure, List<TransactionModel>>> call() =>
      repository.getTransactionHistory();
}

class GetAchievementsUseCase {
  final ProfileRepository repository;
  GetAchievementsUseCase(this.repository);
  Future<Either<Failure, List<AchievementModel>>> call() =>
      repository.getAchievements();
}