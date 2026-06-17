import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reward.dart';

abstract class RewardsRepository {
  Future<Either<Failure, List<Reward>>> getActiveRewards();
  Future<Either<Failure, UserCoupon>> redeemReward(String rewardId);
  Future<Either<Failure, List<UserCoupon>>> getMyCoupons();
}