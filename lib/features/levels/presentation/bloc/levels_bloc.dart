import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/level.dart';
import '../../domain/usecases/get_levels_usecase.dart';

// Events
abstract class LevelsEvent extends Equatable {
  const LevelsEvent();
  @override
  List<Object> get props => [];
}

class LevelsLoadEvent extends LevelsEvent {}

// States
abstract class LevelsState extends Equatable {
  const LevelsState();
  @override
  List<Object?> get props => [];
}

class LevelsInitial extends LevelsState {}
class LevelsLoading extends LevelsState {}

class LevelsLoaded extends LevelsState {
  final List<Level> levels;
  const LevelsLoaded(this.levels);
  @override
  List<Object> get props => [levels];
}

class LevelsError extends LevelsState {
  final String message;
  const LevelsError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class LevelsBloc extends Bloc<LevelsEvent, LevelsState> {
  final GetLevelsUseCase _getLevels;

  LevelsBloc(this._getLevels) : super(LevelsInitial()) {
    on<LevelsLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(LevelsLoadEvent event, Emitter<LevelsState> emit) async {
    emit(LevelsLoading());
    final result = await _getLevels();
    result.fold(
          (f) => emit(LevelsError(f.message)),
          (levels) => emit(LevelsLoaded(levels)),
    );
  }
}