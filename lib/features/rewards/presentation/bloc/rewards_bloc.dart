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
class RewardsFilterChanged extends RewardsEvent {
  final RewardFilter filter;
  const RewardsFilterChanged(this.filter);
  @override
  List<Object> get props => [filter];
}

enum RewardFilter {
  all('Todos'),
  active('Activos'),
  lowStock('Poco stock'),
  expiringSoon('Pronto a vencer'),
  expired('Vencidos');

  const RewardFilter(this.label);
  final String label;

  bool matches(Reward reward) => switch (this) {
        RewardFilter.all => true,
        RewardFilter.active => reward.isAvailable,
        RewardFilter.lowStock => reward.hasLowStock,
        RewardFilter.expiringSoon => reward.expiresSoon,
        RewardFilter.expired => reward.isExpired,
      };
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
  final RewardFilter selectedFilter;
  final String? redeemingRewardId;

  const RewardsLoaded({
    required this.rewards,
    required this.filtered,
    this.selectedFilter = RewardFilter.all,
    this.redeemingRewardId,
  });

  RewardsLoaded copyWith({
    List<Reward>? rewards,
    List<Reward>? filtered,
    RewardFilter? selectedFilter,
    String? redeemingRewardId,
  }) {
    return RewardsLoaded(
      rewards: rewards ?? this.rewards,
      filtered: filtered ?? this.filtered,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      // If redeemingRewardId is passed as null in copyWith, it remains null. 
      // To specifically clear it, we just provide the constructor directly below.
      redeemingRewardId: redeemingRewardId ?? this.redeemingRewardId,
    );
  }

  RewardsLoaded clearRedeeming() {
    return RewardsLoaded(
      rewards: rewards,
      filtered: filtered,
      selectedFilter: selectedFilter,
      redeemingRewardId: null,
    );
  }

  @override
  List<Object?> get props => [rewards, filtered, selectedFilter, redeemingRewardId];
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
  bool _loadingRewards = false;

  RewardsBloc(this._getActiveRewards, this._redeemReward, this._getMyCoupons)
      : super(RewardsInitial()) {
    on<RewardsLoadEvent>(_onLoad);
    on<RewardsFilterChanged>(_onFilter);
    on<RewardsRedeemEvent>(_onRedeem);
    on<RewardsLoadCouponsEvent>(_onLoadCoupons);
  }

  Future<void> _onLoad(RewardsLoadEvent event, Emitter<RewardsState> emit) async {
    if (_loadingRewards) return;
    _loadingRewards = true;
    emit(RewardsLoading());
    try {
      final result = await _getActiveRewards();
      result.fold(
        (f) => emit(RewardsError(f.message)),
        (rewards) => emit(RewardsLoaded(rewards: rewards, filtered: rewards)),
      );
    } finally {
      _loadingRewards = false;
    }
  }

  void _onFilter(RewardsFilterChanged event, Emitter<RewardsState> emit) {
    final current = state;
    if (current is! RewardsLoaded || current.redeemingRewardId != null) return;
    emit(current.copyWith(
      filtered: current.rewards.where(event.filter.matches).toList(),
      selectedFilter: event.filter,
    ));
  }

  Future<void> _onRedeem(RewardsRedeemEvent event, Emitter<RewardsState> emit) async {
    if (state is! RewardsLoaded ||
        (state as RewardsLoaded).redeemingRewardId != null) {
      return;
    }
    RewardsLoaded? previousLoaded;
    // Solo mostramos cargando si tenemos la lista previa
    if (state is RewardsLoaded) {
      previousLoaded = state as RewardsLoaded;
      emit(previousLoaded.copyWith(redeemingRewardId: event.rewardId));
    }
    
    final result = await _redeemReward(event.rewardId);
    
    result.fold(
      (f) {
        emit(RewardsError(f.message));
        if (previousLoaded != null) {
          emit(previousLoaded.clearRedeeming());
        }
      },
      (coupon) {
        emit(RewardsRedeemSuccess(coupon));
        if (previousLoaded != null) {
          emit(previousLoaded.clearRedeeming());
        }
      },
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
