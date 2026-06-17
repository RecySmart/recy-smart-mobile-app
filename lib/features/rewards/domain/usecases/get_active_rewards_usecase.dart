import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reward.dart';
import '../repositories/rewards_repository.dart';

class GetActiveRewardsUseCase {
  final RewardsRepository repository;
  GetActiveRewardsUseCase(this.repository);
  Future<Either<Failure, List<Reward>>> call() => repository.getActiveRewards();
}

class RedeemRewardUseCase {
  final RewardsRepository repository;
  RedeemRewardUseCase(this.repository);
  Future<Either<Failure, UserCoupon>> call(String rewardId) =>
      repository.redeemReward(rewardId);
}

class GetMyCouponsUseCase {
  final RewardsRepository repository;
  GetMyCouponsUseCase(this.repository);
  Future<Either<Failure, List<UserCoupon>>> call() => repository.getMyCoupons();
}