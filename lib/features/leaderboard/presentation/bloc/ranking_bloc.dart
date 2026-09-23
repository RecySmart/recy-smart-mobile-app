import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/ranking.dart';
import '../../domain/usecases/get_ranking_usecase.dart';

sealed class RankingEvent extends Equatable {
  const RankingEvent();

  @override
  List<Object> get props => [];
}

class RankingLoadRequested extends RankingEvent {
  final RankingPeriod period;
  final int page;

  const RankingLoadRequested({required this.period, this.page = 1});

  @override
  List<Object> get props => [period, page];
}

sealed class RankingState extends Equatable {
  const RankingState();

  @override
  List<Object?> get props => [];
}

class RankingInitial extends RankingState {}

class RankingLoading extends RankingState {}

class RankingLoaded extends RankingState {
  final Ranking ranking;

  const RankingLoaded(this.ranking);

  @override
  List<Object> get props => [ranking];
}

class RankingError extends RankingState {
  final String message;

  const RankingError(this.message);

  @override
  List<Object> get props => [message];
}

class RankingBloc extends Bloc<RankingEvent, RankingState> {
  final GetRankingUseCase _getRanking;

  RankingBloc(this._getRanking) : super(RankingInitial()) {
    on<RankingLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    RankingLoadRequested event,
    Emitter<RankingState> emit,
  ) async {
    emit(RankingLoading());
    final result = await _getRanking(period: event.period, page: event.page);
    result.fold(
      (failure) => emit(RankingError(failure.message)),
      (ranking) => emit(RankingLoaded(ranking)),
    );
  }
}
