import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/usecases/start_session_usecase.dart';
import '../../../home/presentation/bloc/home_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class RecyclingEvent extends Equatable {
  const RecyclingEvent();
  @override
  List<Object?> get props => [];
}

/// Raw QR string scanned from the bin's physical code.
/// Expected JSON: { "smartBinId": "...", "qrToken": "...",
///                  "latitude": -12.059, "longitude": -77.036 }
class RecyclingQrScannedEvent extends RecyclingEvent {
  final String rawQr;
  const RecyclingQrScannedEvent(this.rawQr);
  @override
  List<Object> get props => [rawQr];
}

/// User pressed "Finalizar Sesión"
class RecyclingFinishSessionEvent extends RecyclingEvent {}

/// WebSocket session_update received
class RecyclingWsSessionUpdateEvent extends RecyclingEvent {
  final Map<String, dynamic> data;
  const RecyclingWsSessionUpdateEvent(this.data);
  @override
  List<Object> get props => [data];
}

/// Local countdown tick (display only)
class RecyclingTimerTickEvent extends RecyclingEvent {
  final int secondsRemaining;
  const RecyclingTimerTickEvent(this.secondsRemaining);
  @override
  List<Object> get props => [secondsRemaining];
}

/// Local timer hit 0 — fallback if WS never sends session_timeout
class RecyclingLocalTimeoutEvent extends RecyclingEvent {}

// ── States ────────────────────────────────────────────────────────────────────

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
  final bool bottleRejected;
  // Increments on every rejection so Equatable always sees a new state
  final int rejectionCount;

  const RecyclingSessionActive({
    required this.session,
    required this.timerSeconds,
    this.bottleRejected = false,
    this.rejectionCount = 0,
  });

  RecyclingSessionActive copyWithTimer(int t) => RecyclingSessionActive(
    session: session,
    timerSeconds: t,
    bottleRejected: bottleRejected,
    rejectionCount: rejectionCount,
  );

  @override
  List<Object> get props => [session, timerSeconds, bottleRejected, rejectionCount];
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

// ── BLoC ──────────────────────────────────────────────────────────────────────

class RecyclingBloc extends Bloc<RecyclingEvent, RecyclingState> {
  final StartSessionUseCase _startSession;
  final EndSessionUseCase _endSession;
  final HomeBloc _homeBloc;
  final SocketService _socketService;
  final StorageService _storage;

  Timer? _tickTimer;
  int _secondsRemaining = AppConstants.sessionAutoCloseSeconds;

  RecyclingBloc({
    required StartSessionUseCase startSession,
    required EndSessionUseCase endSession,
    required HomeBloc homeBloc,
    required SocketService socketService,
    required StorageService storage,
  })  : _startSession = startSession,
        _endSession = endSession,
        _homeBloc = homeBloc,
        _socketService = socketService,
        _storage = storage,
        super(RecyclingIdle()) {
    on<RecyclingQrScannedEvent>(_onQrScanned);
    on<RecyclingFinishSessionEvent>(_onFinishSession);
    on<RecyclingWsSessionUpdateEvent>(_onWsSessionUpdate);
    on<RecyclingTimerTickEvent>(_onTimerTick);
    on<RecyclingLocalTimeoutEvent>(_onLocalTimeout);
  }

  // ── QR Scanned ────────────────────────────────────────────────────────────

  Future<void> _onQrScanned(
      RecyclingQrScannedEvent event, Emitter<RecyclingState> emit) async {
    emit(RecyclingConnecting());

    // 1. Parse QR — expected JSON from the bin's physical QR code
    Map<String, dynamic> qrData;
    try {
      qrData = jsonDecode(event.rawQr) as Map<String, dynamic>;
    } catch (_) {
      // Fallback: treat the raw value as the smartBinId/qrToken
      // (for manual entry or plain-text QR codes)
      qrData = {
        'smartBinId': event.rawQr,
        'qrToken': event.rawQr,
        'latitude': -12.059432,
        'longitude': -77.036041,
      };
    }

    final smartBinId = qrData['smartBinId'] as String? ??
        qrData['binId'] as String? ?? '';
    final qrToken = qrData['qrToken'] as String? ??
        qrData['token'] as String? ?? event.rawQr;
    final latitude  = (qrData['latitude']  as num?)?.toDouble() ?? -12.059432;
    final longitude = (qrData['longitude'] as num?)?.toDouble() ?? -77.036041;

    // 2. Get userId from local storage
    final userId = await _storage.read(key: AppConstants.userIdKey) ?? '';
    if (userId.isEmpty) {
      emit(const RecyclingError('No se encontró tu usuario. Vuelve a iniciar sesión.'));
      return;
    }

    // 3. Call REST endpoint
    final result = await _startSession(
      userId: userId,
      smartBinId: smartBinId,
      qrToken: qrToken,
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
          (failure) => emit(RecyclingError(failure.message)),
          (session) {
        // 4. Connect WebSocket after session created
        _socketService.connect(
          sessionId: session.sessionId,
          userId: userId,
          onSessionUpdate: (data) {
            if (!isClosed) add(RecyclingWsSessionUpdateEvent(data));
          },
          onPointsUpdate: (_) {
            _homeBloc.add(HomeRefreshEvent());
          },
          onAchievementUnlocked: (data) {
            debugPrint('🏆 Achievement: ${data['name']}');
          },
        );

        // 5. Start local countdown
        _startLocalTimer();

        emit(RecyclingSessionActive(
          session: session,
          timerSeconds: AppConstants.sessionAutoCloseSeconds,
        ));
      },
    );
  }

  // ── WebSocket session_update ──────────────────────────────────────────────

  void _onWsSessionUpdate(
      RecyclingWsSessionUpdateEvent event, Emitter<RecyclingState> emit) {
    if (state is! RecyclingSessionActive) return;
    final current = (state as RecyclingSessionActive).session;
    final wsEvent = event.data['event'] as String? ?? '';

    debugPrint('🔄 WS event: $wsEvent | data: ${event.data}');

    switch (wsEvent) {
      case 'bottle_accepted':
        final timeout = (event.data['timeoutSeconds'] as num?)?.toInt()
            ?? AppConstants.sessionAutoCloseSeconds;
        _resetLocalTimer(timeout);

        final bottles = (event.data['bottlesDeposited'] as num?)?.toInt()
            ?? current.bottlesDropped + 1;
        final points = (event.data['pointsEarned'] as num?)?.toInt()
            ?? bottles * AppConstants.pointsPerBottle;

        emit(RecyclingSessionActive(
          session: current.copyWith(
            bottlesDropped: bottles,
            pointsEarned: points,
            co2Saved: bottles * 0.04,
            lastWsEvent: 'bottle_accepted',
          ),
          timerSeconds: _secondsRemaining,
          bottleRejected: false,
        ));
        break;

      case 'bottle_rejected':
        final timeout = (event.data['timeoutSeconds'] as num?)?.toInt()
            ?? AppConstants.sessionAutoCloseSeconds;
        _resetLocalTimer(timeout);

        final newCount = (state as RecyclingSessionActive).rejectionCount + 1;
        emit(RecyclingSessionActive(
          session: current.copyWith(lastWsEvent: 'bottle_rejected'),
          timerSeconds: _secondsRemaining,
          bottleRejected: true,
          rejectionCount: newCount,
        ));
        // Clear rejection warning after 2s
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed && state is RecyclingSessionActive) {
            final s = state as RecyclingSessionActive;
            if (s.bottleRejected) {
              emit(RecyclingSessionActive(
                session: s.session.copyWith(lastWsEvent: null),
                timerSeconds: s.timerSeconds,
                bottleRejected: false,
                rejectionCount: s.rejectionCount,
              ));
            }
          }
        });
        break;

      case 'session_success':
      case 'session_timeout':
        _cancelLocalTimer();
        _socketService.disconnect();
        _homeBloc.add(HomeRefreshEvent());

        final finalBottles = (event.data['bottlesDeposited'] as num?)?.toInt()
            ?? current.bottlesDropped;
        final finalPoints = (event.data['pointsEarned'] as num?)?.toInt()
            ?? current.pointsEarned;

        emit(RecyclingSessionCompleted(
          session: current.copyWith(
            bottlesDropped: finalBottles,
            pointsEarned: finalPoints,
            co2Saved: finalBottles * 0.04,
          ),
          autoClosed: wsEvent == 'session_timeout',
        ));
        break;
    }
  }

  // ── Finish Session (manual) ───────────────────────────────────────────────

  Future<void> _onFinishSession(
      RecyclingFinishSessionEvent event, Emitter<RecyclingState> emit) async {
    if (state is! RecyclingSessionActive) return;
    final session = (state as RecyclingSessionActive).session;

    _cancelLocalTimer();
    await _endSession(session.sessionId);
    _socketService.disconnect();
    _homeBloc.add(HomeRefreshEvent());

    emit(RecyclingSessionCompleted(session: session, autoClosed: false));
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _onTimerTick(
      RecyclingTimerTickEvent event, Emitter<RecyclingState> emit) {
    if (state is! RecyclingSessionActive) return;
    emit((state as RecyclingSessionActive).copyWithTimer(event.secondsRemaining));
  }

  void _onLocalTimeout(
      RecyclingLocalTimeoutEvent event, Emitter<RecyclingState> emit) {
    if (state is! RecyclingSessionActive) return;
    final session = (state as RecyclingSessionActive).session;
    _cancelLocalTimer();
    _socketService.disconnect();
    _homeBloc.add(HomeRefreshEvent());
    emit(RecyclingSessionCompleted(session: session, autoClosed: true));
  }

  void _startLocalTimer() {
    _cancelLocalTimer();
    _secondsRemaining = AppConstants.sessionAutoCloseSeconds;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        t.cancel();
        if (!isClosed) add(RecyclingLocalTimeoutEvent());
      } else {
        if (!isClosed) add(RecyclingTimerTickEvent(_secondsRemaining));
      }
    });
  }

  void _resetLocalTimer(int seconds) {
    _secondsRemaining = seconds;
  }

  void _cancelLocalTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  @override
  Future<void> close() {
    _cancelLocalTimer();
    _socketService.disconnect();
    return super.close();
  }
}