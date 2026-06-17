import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/usecases/get_home_data_usecase.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

class HomeLoadEvent extends HomeEvent {}
class HomeRefreshEvent extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final HomeData data;
  const HomeLoaded(this.data);
  @override
  List<Object> get props => [data];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeDataUseCase _getHomeData;

  HomeBloc(this._getHomeData) : super(HomeInitial()) {
    on<HomeLoadEvent>(_onLoad);
    on<HomeRefreshEvent>(_onLoad);
  }

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    if (event is HomeLoadEvent) emit(HomeLoading());
    final result = await _getHomeData();
    result.fold(
          (failure) => emit(HomeError(failure.message)),
          (data) => emit(HomeLoaded(data)),
    );
  }
}