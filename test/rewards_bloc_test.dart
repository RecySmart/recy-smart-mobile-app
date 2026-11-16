import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recysmart/core/errors/failures.dart';
import 'package:recysmart/features/rewards/domain/entities/reward.dart';
import 'package:recysmart/features/rewards/domain/usecases/get_active_rewards_usecase.dart';
import 'package:recysmart/features/rewards/presentation/bloc/rewards_bloc.dart';

class MockGetRewards extends Mock implements GetActiveRewardsUseCase {}
class MockRedeemReward extends Mock implements RedeemRewardUseCase {}
class MockGetCoupons extends Mock implements GetMyCouponsUseCase {}

void main() {
  late MockGetRewards getRewards;
  late MockRedeemReward redeem;
  late MockGetCoupons getCoupons;
  late RewardsBloc bloc;
  const reward = Reward(
    id: 'reward-1', companyId: 'company-1', companyName: 'Aliado',
    title: 'Viaje', description: 'Premio', costInPoints: 10,
    remainingStock: 1, status: 'ACTIVE', category: 'Transporte',
  );

  setUp(() {
    getRewards = MockGetRewards();
    redeem = MockRedeemReward();
    getCoupons = MockGetCoupons();
    bloc = RewardsBloc(getRewards, redeem, getCoupons);
  });

  tearDown(() => bloc.close());

  test('failed catalog stays in error until an explicit retry', () async {
    when(() => getRewards()).thenAnswer((_) async =>
        const Left(ServerFailure('offline')));
    final error = bloc.stream.firstWhere((s) => s is RewardsError);
    bloc.add(RewardsLoadEvent());
    await error;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state, isA<RewardsError>());
    verify(() => getRewards()).called(1);
  });

  test('filters the catalog by availability and upcoming expiration', () async {
    final now = DateTime.now();
    Reward catalogReward(String id, int stock, String status, {DateTime? expiresAt}) =>
        Reward(
          id: id,
          companyId: 'company-1',
          companyName: 'Aliado',
          title: 'Premio',
          description: 'Descripción',
          costInPoints: 10,
          remainingStock: stock,
          status: status,
          expiresAt: expiresAt?.toIso8601String(),
        );
    final soon = catalogReward('soon', 8, 'ACTIVE',
        expiresAt: now.add(const Duration(days: 3)));
    final expired = catalogReward('expired', 4, 'ACTIVE',
        expiresAt: now.subtract(const Duration(days: 1)));
    final paused = catalogReward('paused', 3, 'DISCONTINUED',
        expiresAt: now.add(const Duration(days: 2)));
    final later = catalogReward('later', 7, 'ACTIVE',
        expiresAt: now.add(const Duration(days: 8)));
    final empty = catalogReward('empty', 0, 'OUT_OF_STOCK');
    final catalog = [reward, soon, expired, paused, later, empty];

    when(() => getRewards()).thenAnswer((_) async => Right(catalog));
    final loaded = bloc.stream.firstWhere((s) => s is RewardsLoaded);
    bloc.add(RewardsLoadEvent());
    expect((await loaded as RewardsLoaded).filtered, catalog);

    final cases = {
      RewardFilter.active: [reward, soon, later],
      RewardFilter.lowStock: [reward],
      RewardFilter.expiringSoon: [soon],
      RewardFilter.expired: [expired],
    };
    for (final entry in cases.entries) {
      final filtered = bloc.stream.firstWhere(
        (s) => s is RewardsLoaded && s.selectedFilter == entry.key,
      );
      bloc.add(RewardsFilterChanged(entry.key));
      expect((await filtered as RewardsLoaded).filtered, entry.value);
    }
  });

  test('failed redeem keeps the selected filter and list', () async {
    when(() => getRewards()).thenAnswer((_) async => const Right([reward]));
    when(() => redeem('reward-1')).thenAnswer((_) async =>
        const Left(ServerFailure('offline')));
    final loaded = bloc.stream.firstWhere((s) => s is RewardsLoaded);
    bloc.add(RewardsLoadEvent());
    await loaded;
    final filtered = bloc.stream.firstWhere((s) =>
        s is RewardsLoaded && s.selectedFilter == RewardFilter.lowStock);
    bloc.add(const RewardsFilterChanged(RewardFilter.lowStock));
    await filtered;
    final error = bloc.stream.firstWhere((s) => s is RewardsError);
    bloc.add(const RewardsRedeemEvent('reward-1'));
    await error;
    await Future<void>.delayed(Duration.zero);
    final state = bloc.state as RewardsLoaded;
    expect(state.selectedFilter, RewardFilter.lowStock);
    expect(state.filtered, [reward]);
    verify(() => getRewards()).called(1);
  });

  test('coupon missing state', () async {
    when(() => getCoupons()).thenAnswer((_) async => const Left(ServerFailure('Coupon not found')));
    final error = bloc.stream.firstWhere((s) => s is RewardsError);
    bloc.add(RewardsLoadCouponsEvent());
    await error;
    expect(bloc.state, isA<RewardsError>());
  });
}
