import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/reward.dart';
import '../../domain/usecases/get_active_rewards_usecase.dart';

// Events
abstract class RewardsEvent extends Equatable {
  const RewardsEvent();
  @override
  List<Object?> get props => [];
}

class RewardsLoadEvent extends RewardsEvent {}
class RewardsCategoryFilterEvent extends RewardsEvent {
  final String category;
  const RewardsCategoryFilterEvent(this.category);
  @override
  List<Object> get props => [category];
}

class RewardsRedeemEvent extends RewardsEvent {
  final String rewardId;
  const RewardsRedeemEvent(this.rewardId);
  @override
  List<Object> get props => [rewardId];
}

class RewardsLoadCouponsEvent extends RewardsEvent {}

// States
abstract class RewardsState extends Equatable {
  const RewardsState();
  @override
  List<Object?> get props => [];
}

class RewardsInitial extends RewardsState {}
class RewardsLoading extends RewardsState {}

class RewardsLoaded extends RewardsState {
  final List<Reward> rewards;
  final List<Reward> filtered;
  final String selectedCategory;
  const RewardsLoaded({
    required this.rewards,
    required this.filtered,
    this.selectedCategory = 'All',
  });
  @override
  List<Object> get props => [rewards, filtered, selectedCategory];
}

class RewardsRedeemLoading extends RewardsState {
  final String rewardId;
  const RewardsRedeemLoading(this.rewardId);
}

class RewardsRedeemSuccess extends RewardsState {
  final UserCoupon coupon;
  const RewardsRedeemSuccess(this.coupon);
  @override
  List<Object> get props => [coupon];
}

class RewardsCouponsLoaded extends RewardsState {
  final List<UserCoupon> coupons;
  const RewardsCouponsLoaded(this.coupons);
  @override
  List<Object> get props => [coupons];
}

class RewardsError extends RewardsState {
  final String message;
  const RewardsError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  final GetActiveRewardsUseCase _getActiveRewards;
  final RedeemRewardUseCase _redeemReward;
  final GetMyCouponsUseCase _getMyCoupons;

  RewardsBloc(this._getActiveRewards, this._redeemReward, this._getMyCoupons)
      : super(RewardsInitial()) {
    on<RewardsLoadEvent>(_onLoad);
    on<RewardsCategoryFilterEvent>(_onFilter);
    on<RewardsRedeemEvent>(_onRedeem);
    on<RewardsLoadCouponsEvent>(_onLoadCoupons);
  }

  Future<void> _onLoad(RewardsLoadEvent event, Emitter<RewardsState> emit) async {
    emit(RewardsLoading());
    final result = await _getActiveRewards();
    result.fold(
          (f) => emit(RewardsError(f.message)),
          (rewards) => emit(RewardsLoaded(rewards: rewards, filtered: rewards)),
    );
  }

  void _onFilter(RewardsCategoryFilterEvent event, Emitter<RewardsState> emit) {
    if (state is! RewardsLoaded) return;
    final current = state as RewardsLoaded;
    final filtered = event.category == 'All'
        ? current.rewards
        : current.rewards.where((r) => r.category == event.category).toList();
    emit(RewardsLoaded(
      rewards: current.rewards,
      filtered: filtered,
      selectedCategory: event.category,
    ));
  }

  Future<void> _onRedeem(RewardsRedeemEvent event, Emitter<RewardsState> emit) async {
    emit(RewardsRedeemLoading(event.rewardId));
    final result = await _redeemReward(event.rewardId);
    result.fold(
          (f) => emit(RewardsError(f.message)),
          (coupon) => emit(RewardsRedeemSuccess(coupon)),
    );
  }

  Future<void> _onLoadCoupons(
      RewardsLoadCouponsEvent event, Emitter<RewardsState> emit) async {
    emit(RewardsLoading());
    final result = await _getMyCoupons();
    result.fold(
          (f) => emit(RewardsError(f.message)),
          (coupons) => emit(RewardsCouponsLoaded(coupons)),
    );
  }
}