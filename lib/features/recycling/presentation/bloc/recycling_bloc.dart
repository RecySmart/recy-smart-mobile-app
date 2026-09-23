import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../../core/services/location_service.dart';
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

/// Clear rejection warning state
class RecyclingClearRejectionEvent extends RecyclingEvent {}

class RecyclingRestoreSessionEvent extends RecyclingEvent {
  final String userId;
  const RecyclingRestoreSessionEvent(this.userId);
  @override
  List<Object> get props => [userId];
}

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
  final bool bottleError;
  // Increments on every rejection so Equatable always sees a new state
  final int rejectionCount;
  final bool isEnding;
  final bool recovered;

  const RecyclingSessionActive({
    required this.session,
    required this.timerSeconds,
    this.bottleRejected = false,
    this.bottleError = false,
    this.rejectionCount = 0,
    this.isEnding = false,
    this.recovered = false,
  });

  RecyclingSessionActive copyWithTimer(int t) => RecyclingSessionActive(
    session: session,
    timerSeconds: t,
    bottleRejected: bottleRejected,
    bottleError: bottleError,
    rejectionCount: rejectionCount,
    isEnding: isEnding,
    recovered: recovered,
  );

  RecyclingSessionActive copyWithEnding(bool ending) => RecyclingSessionActive(
    session: session,
    timerSeconds: timerSeconds,
    bottleRejected: bottleRejected,
    bottleError: bottleError,
    rejectionCount: rejectionCount,
    isEnding: ending,
    recovered: recovered,
  );

  @override
  List<Object> get props => [session, timerSeconds, bottleRejected, bottleError, rejectionCount, isEnding, recovered];
}

class RecyclingRecoveryPending extends RecyclingState {
  final String userId;
  final String message;
  const RecyclingRecoveryPending(this.userId, this.message);
  @override
  List<Object> get props => [userId, message];
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

class RecyclingEndSessionFailed extends RecyclingState {
  final String message;
  const RecyclingEndSessionFailed(this.message);
  @override
  List<Object> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class RecyclingBloc extends Bloc<RecyclingEvent, RecyclingState> {
  final StartSessionUseCase _startSession;
  final EndSessionUseCase _endSession;
  final GetSessionStatusUseCase _getSessionStatus;
  final HomeBloc _homeBloc;
  final SocketService _socketService;
  final StorageService _storage;
  final LocationService _locationService;

  Timer? _tickTimer;
  int _secondsRemaining = AppConstants.sessionAutoCloseSeconds;
  bool _restoring = false;

  RecyclingBloc({
    required StartSessionUseCase startSession,
    required EndSessionUseCase endSession,
    required GetSessionStatusUseCase getSessionStatus,
    required HomeBloc homeBloc,
    required SocketService socketService,
    required StorageService storage,
    required LocationService locationService,
  })  : _startSession = startSession,
        _endSession = endSession,
        _getSessionStatus = getSessionStatus,
        _homeBloc = homeBloc,
        _socketService = socketService,
        _storage = storage,
        _locationService = locationService,
        super(RecyclingIdle()) {
    on<RecyclingQrScannedEvent>(_onQrScanned);
    on<RecyclingFinishSessionEvent>(_onFinishSession);
    on<RecyclingWsSessionUpdateEvent>(_onWsSessionUpdate);
    on<RecyclingTimerTickEvent>(_onTimerTick);
    on<RecyclingLocalTimeoutEvent>(_onLocalTimeout);
    on<RecyclingClearRejectionEvent>(_onClearRejection);
    on<RecyclingRestoreSessionEvent>(_onRestoreSession);
  }

  Future<void> _onRestoreSession(
      RecyclingRestoreSessionEvent event, Emitter<RecyclingState> emit) async {
    if (_restoring || state is RecyclingSessionActive ||
        state is RecyclingSessionCompleted) {
      return;
    }
    _restoring = true;
    try {
      final raw = await _storage.read(key: AppConstants.activeRecyclingSessionKey);
      if (raw == null) return;
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      if (saved['userId'] != event.userId) return;
      final result = await _getSessionStatus(saved['sessionId'] as String);
      await result.fold<Future<void>>(
        (failure) async => emit(RecyclingRecoveryPending(
          event.userId, 'No se pudo verificar la sesión anterior: ${failure.message}',
        )),
        (snapshot) async {
          final session = RecyclingSession(
            sessionId: snapshot.sessionId,
            binId: snapshot.smartBinId,
            locationName: 'Punto RecySmart',
            bottlesDropped: snapshot.bottlesAccepted,
            pointsEarned: snapshot.pointsCalculated,
          );
          if (snapshot.isActive) {
            _connectSocket(session.sessionId, event.userId);
            final seconds = snapshot.expiresAt?.difference(DateTime.now()).inSeconds ??
                AppConstants.sessionAutoCloseSeconds;
            _startLocalTimer(seconds > 0 ? seconds : 1);
            emit(RecyclingSessionActive(
              session: session, timerSeconds: _secondsRemaining, recovered: true,
            ));
          } else {
            await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
            _homeBloc.add(HomeRefreshEvent());
            emit(RecyclingSessionCompleted(
              session: session, autoClosed: snapshot.status == 'TIMED_OUT',
            ));
          }
        },
      );
    } catch (e) {
      emit(RecyclingRecoveryPending(event.userId,
          'No se pudo leer la sesión anterior: $e'));
    } finally {
      _restoring = false;
    }
  }

  void _connectSocket(String sessionId, String userId) {
    _socketService.connect(
      sessionId: sessionId,
      userId: userId,
      onSessionUpdate: (data) {
        if (!isClosed) add(RecyclingWsSessionUpdateEvent(data));
      },
      onPointsUpdate: (_) => _homeBloc.add(HomeRefreshEvent()),
      onAchievementUnlocked: (data) => debugPrint('Achievement: ${data['name']}'),
    );
  }

  Future<bool> _reconcileClose(
      RecyclingSession session, bool autoClosed, Emitter<RecyclingState> emit) async {
    try {
      final result = await _getSessionStatus(session.sessionId);
      final snapshot = result.fold<RecyclingSessionSnapshot?>(
        (_) => null, (value) => value,
      );
      if (snapshot == null || snapshot.isActive ||
          state is RecyclingSessionCompleted) {
        return false;
      }
      await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
      _cancelLocalTimer();
      _socketService.disconnect();
      _homeBloc.add(HomeRefreshEvent());
      emit(RecyclingSessionCompleted(
        session: session.copyWith(
          bottlesDropped: snapshot.bottlesAccepted,
          pointsEarned: snapshot.pointsCalculated,
        ),
        autoClosed: autoClosed,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── QR Scanned ────────────────────────────────────────────────────────────

  Future<void> _onQrScanned(
      RecyclingQrScannedEvent event, Emitter<RecyclingState> emit) async {
    emit(RecyclingConnecting());

    // Request location permission in the demo, while preserving QR coordinates
    // for the prototype's configured geofence.
    try {
      await _locationService.getCurrentPosition();
    } catch (e) {
      emit(RecyclingError(e.toString().replaceAll('Exception: ', '')));
      return;
    }

    // Parse QR — expected JSON from the bin's physical QR code.
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
    
    // The prototype's geofence is configured for the coordinates in its QR.
    final latitude  = (qrData['latitude']  as num?)?.toDouble() ?? -12.059432;
    final longitude = (qrData['longitude'] as num?)?.toDouble() ?? -77.036041;

    // 3. Get userId from local storage
    final userId = await _storage.read(key: AppConstants.userIdKey) ?? '';
    if (userId.isEmpty) {
      emit(const RecyclingError('No se encontró tu usuario. Vuelve a iniciar sesión.'));
      return;
    }

    // 4. Call REST endpoint
    final result = await _startSession(
      userId: userId,
      smartBinId: smartBinId,
      qrToken: qrToken,
      latitude: latitude,
      longitude: longitude,
    );

    await result.fold<Future<void>>(
          (failure) async => emit(RecyclingError(failure.message)),
          (session) async {
        await _storage.write(
          key: AppConstants.activeRecyclingSessionKey,
          value: jsonEncode({'userId': userId, 'sessionId': session.sessionId}),
        );
        // 4. Connect WebSocket after session created
        _connectSocket(session.sessionId, userId);

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
        bottleError: false,
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
        
        // Limpiamos la alerta luego de 2 segundos, pero usando un nuevo evento 
        // en vez de emitir directamente fuera del handler.
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) {
            add(RecyclingClearRejectionEvent());
          }
        });
        break;

      case 'bottle_error':
        // Un error inesperado de hardware del tacho
        final timeout = (event.data['timeoutSeconds'] as num?)?.toInt()
            ?? AppConstants.sessionAutoCloseSeconds;
        _resetLocalTimer(timeout);

        final newCount = (state as RecyclingSessionActive).rejectionCount + 1;
        emit(RecyclingSessionActive(
          session: current.copyWith(lastWsEvent: 'bottle_error'),
          timerSeconds: _secondsRemaining,
          bottleError: true,
          rejectionCount: newCount,
        ));
        
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) {
            add(RecyclingClearRejectionEvent());
          }
        });
        break;

      case 'session_success':
      case 'session_timeout':
        unawaited(_storage.delete(key: AppConstants.activeRecyclingSessionKey));
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

  // ── WS Event Helpers ──────────────────────────────────────────────────────
  
  void _onClearRejection(
      RecyclingClearRejectionEvent event, Emitter<RecyclingState> emit) {
    if (state is! RecyclingSessionActive) return;
    final s = state as RecyclingSessionActive;
    if (s.bottleRejected || s.bottleError) {
      emit(RecyclingSessionActive(
        session: s.session.copyWith(lastWsEvent: null),
        timerSeconds: s.timerSeconds,
        bottleRejected: false,
        bottleError: false,
        rejectionCount: s.rejectionCount,
      ));
    }
  }

  // ── Finish Session (manual) ───────────────────────────────────────────────

  Future<void> _onFinishSession(
      RecyclingFinishSessionEvent event, Emitter<RecyclingState> emit) async {
    if (state is! RecyclingSessionActive) return;
    final session = (state as RecyclingSessionActive).session;

    _cancelLocalTimer();
    
    // Mostramos estado conectando (loading button)
    emit((state as RecyclingSessionActive).copyWithEnding(true));
    final result = await _endSession(session.sessionId);
    if (state is RecyclingSessionCompleted) return;
    
    await result.fold<Future<void>>(
      (failure) async {
        if (await _reconcileClose(session, false, emit)) return;
        // Falló el cierre en backend. Retenemos la sesión para que intente de nuevo
        emit(RecyclingEndSessionFailed(failure.message));
        // Volvemos a iniciar el timer para que no se quede colgado indefinidamente
        _startLocalTimer();
        emit(RecyclingSessionActive(
          session: session,
          timerSeconds: _secondsRemaining,
          isEnding: false,
        ));
      },
      (_) async {
        // Éxito. Cerramos socket y completamos.
        await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
        _socketService.disconnect();
        _homeBloc.add(HomeRefreshEvent());
        emit(RecyclingSessionCompleted(session: session, autoClosed: false));
      },
    );
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _onTimerTick(
      RecyclingTimerTickEvent event, Emitter<RecyclingState> emit) {
    if (state is! RecyclingSessionActive) return;
    emit((state as RecyclingSessionActive).copyWithTimer(event.secondsRemaining));
  }

  Future<void> _onLocalTimeout(
      RecyclingLocalTimeoutEvent event, Emitter<RecyclingState> emit) async {
    if (state is! RecyclingSessionActive) return;
    final session = (state as RecyclingSessionActive).session;
    
    _cancelLocalTimer();
    
    // A local countdown does not prove that the server closed the session.
    emit((state as RecyclingSessionActive).copyWithEnding(true));
    final result = await _endSession(session.sessionId);
    if (state is RecyclingSessionCompleted) return;
    await result.fold<Future<void>>(
      (failure) async {
        if (await _reconcileClose(session, true, emit)) return;
        emit(RecyclingEndSessionFailed(
          'Cierre no confirmado: ${failure.message}. Vuelve a intentarlo.',
        ));
        emit(RecyclingSessionActive(
          session: session,
          timerSeconds: 0,
        ));
      },
      (_) async {
        await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
        _socketService.disconnect();
        _homeBloc.add(HomeRefreshEvent());
        emit(RecyclingSessionCompleted(session: session, autoClosed: true));
      },
    );
  }

  void _startLocalTimer([int seconds = AppConstants.sessionAutoCloseSeconds]) {
    _cancelLocalTimer();
    _secondsRemaining = seconds;
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
