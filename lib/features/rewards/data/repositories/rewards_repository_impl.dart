import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_datasource.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  final RewardsRemoteDataSource _remote;
  RewardsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<Reward>>> getActiveRewards() async {
    try {
      final rewards = await _remote.getActiveRewards();
      return Right(rewards);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCoupon>> redeemReward(String rewardId) async {
    try {
      final coupon = await _remote.redeemReward(rewardId);
      return Right(coupon);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserCoupon>>> getMyCoupons() async {
    try {
      final coupons = await _remote.getMyCoupons();
      return Right(coupons);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}