import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/profile_remote_datasource.dart';

abstract class ProfileRepository {
  Future<Either<Failure, List<TransactionModel>>> getTransactionHistory();
  Future<Either<Failure, List<AchievementModel>>> getAchievements();
}