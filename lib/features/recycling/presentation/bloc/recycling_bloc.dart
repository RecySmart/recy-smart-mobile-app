import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/usecases/start_session_usecase.dart';
import '../../../home/presentation/bloc/home_bloc.dart';

// Events
abstract class RecyclingEvent extends Equatable {
  const RecyclingEvent();

  @override
  List<Object?> get props => [];
}

class RecyclingQrScannedEvent extends RecyclingEvent {
  final String binId;

  const RecyclingQrScannedEvent(this.binId);

  @override
  List<Object> get props => [binId];
}

class RecyclingBottleDroppedEvent extends RecyclingEvent {}

class RecyclingFinishSessionEvent extends RecyclingEvent {}

class RecyclingAutoCloseEvent extends RecyclingEvent {}

class RecyclingTimerTickEvent extends RecyclingEvent {
  final int secondsRemaining;

  const RecyclingTimerTickEvent(this.secondsRemaining);

  @override
  List<Object> get props => [secondsRemaining];
}

// States
abstract class RecyclingState extends Equatable {
  const RecyclingState();

  @override
  List<Object?> get props => [];
}

class RecyclingIdle extends RecyclingState {}

class RecyclingConnecting extends RecyclingState {}

class RecyclingSessionActive extends RecyclingState {
  final RecyclingSession session;
  final int timerSeconds;

  const RecyclingSessionActive(
      {required this.session, required this.timerSeconds});

  @override
  List<Object> get props => [session, timerSeconds];
}

class RecyclingSessionCompleted extends RecyclingState {
  final RecyclingSession session;
  final bool autoClosed;

  const RecyclingSessionCompleted(
      {required this.session, this.autoClosed = false});

  @override
  List<Object> get props => [session, autoClosed];
}

class RecyclingError extends RecyclingState {
  final String message;

  const RecyclingError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class RecyclingBloc extends Bloc<RecyclingEvent, RecyclingState> {
  final StartSessionUseCase _startSession;
  final HomeBloc _homeBloc;
  Timer? _autoCloseTimer;
  Timer? _tickTimer;
  int _secondsRemaining = AppConstants.sessionAutoCloseSeconds;

  RecyclingBloc(this._startSession, this._homeBloc) : super(RecyclingIdle()) {
    on<RecyclingQrScannedEvent>(_onQrScanned);
    on<RecyclingBottleDroppedEvent>(_onBottleDropped);
    on<RecyclingFinishSessionEvent>(_onFinishSession);
    on<RecyclingAutoCloseEvent>(_onAutoClose);
    on<RecyclingTimerTickEvent>(_onTimerTick);
  }

  Future<void> _onQrScanned(
      RecyclingQrScannedEvent event, Emitter<RecyclingState> emit) async {
    emit(RecyclingConnecting());
    final result = await _startSession(event.binId);
    result.fold(
      (failure) => emit(RecyclingError(failure.message)),
      (session) {
        _startAutoCloseTimer();
        emit(RecyclingSessionActive(
          session: session,
          timerSeconds: AppConstants.sessionAutoCloseSeconds,
        ));
      },
    );
  }

  void _onBottleDropped(
      RecyclingBottleDroppedEvent event, Emitter<RecyclingState> emit) {
    if (state is! RecyclingSessionActive) return;
    final current = (state as RecyclingSessionActive).session;
    _resetTimer();
    final updated = current.copyWith(
      bottlesDropped: current.bottlesDropped + 1,
      pointsEarned: (current.bottlesDropped + 1) * AppConstants.pointsPerBottle,
      co2Saved: (current.bottlesDropped + 1) * 0.04,
    );
    emit(RecyclingSessionActive(
      session: updated,
      timerSeconds: AppConstants.sessionAutoCloseSeconds,
    ));
  }

  void _onFinishSession(
      RecyclingFinishSessionEvent event, Emitter<RecyclingState> emit) {
    _cancelTimers();
    if (state is RecyclingSessionActive) {
      final session = (state as RecyclingSessionActive).session;
      _homeBloc.add(HomeRefreshEvent());
      emit(RecyclingSessionCompleted(session: session));
    }
  }

  void _onAutoClose(
      RecyclingAutoCloseEvent event, Emitter<RecyclingState> emit) {
    _cancelTimers();
    if (state is RecyclingSessionActive) {
      final session = (state as RecyclingSessionActive).session;
      _homeBloc.add(HomeRefreshEvent());
      emit(RecyclingSessionCompleted(session: session, autoClosed: true));
    }
  }

  void _onTimerTick(
      RecyclingTimerTickEvent event, Emitter<RecyclingState> emit) {
    if (state is RecyclingSessionActive) {
      final current = state as RecyclingSessionActive;
      emit(RecyclingSessionActive(
        session: current.session,
        timerSeconds: event.secondsRemaining,
      ));
    }
  }

  void _startAutoCloseTimer() {
    _cancelTimers();
    _secondsRemaining = AppConstants.sessionAutoCloseSeconds;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        t.cancel();
        add(RecyclingAutoCloseEvent());
      } else {
        add(RecyclingTimerTickEvent(_secondsRemaining));
      }
    });
  }

  void _resetTimer() {
    _secondsRemaining = AppConstants.sessionAutoCloseSeconds;
  }

  void _cancelTimers() {
    _autoCloseTimer?.cancel();
    _tickTimer?.cancel();
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
