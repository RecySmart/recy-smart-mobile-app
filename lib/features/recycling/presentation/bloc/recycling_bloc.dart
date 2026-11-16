import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
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

class RecyclingManualCodeSubmitted extends RecyclingEvent {
  final String code;
  const RecyclingManualCodeSubmitted(this.code);
  @override
  List<Object> get props => [code];
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

/// Reconcile the active session with the server when a socket event is missed.
class RecyclingSyncSessionEvent extends RecyclingEvent {}

/// Local timer hit 0 — fallback if WS never sends session_timeout
class RecyclingLocalTimeoutEvent extends RecyclingEvent {}

/// Clear rejection warning state
class RecyclingClearRejectionEvent extends RecyclingEvent {}

class RecyclingRestoreSessionEvent extends RecyclingEvent {
  final String userId;
  final bool openScanner;
  const RecyclingRestoreSessionEvent(this.userId, {this.openScanner = false});
  @override
  List<Object> get props => [userId, openScanner];
}

class RecyclingResetEvent extends RecyclingEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class RecyclingState extends Equatable {
  const RecyclingState();
  @override
  List<Object?> get props => [];
}

class RecyclingIdle extends RecyclingState {}

class RecyclingCheckingSession extends RecyclingState {}

class RecyclingReadyToScan extends RecyclingState {}

class RecyclingConnecting extends RecyclingState {}

class RecyclingManualStartFailed extends RecyclingState {
  final String message;
  const RecyclingManualStartFailed(this.message);
  @override
  List<Object> get props => [message];
}

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
  final bool openScanner;
  const RecyclingRecoveryPending(
    this.userId,
    this.message, {
    this.openScanner = false,
  });
  @override
  List<Object> get props => [userId, message, openScanner];
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
  final StartManualSessionUseCase _startManualSession;
  final EndSessionUseCase _endSession;
  final GetSessionStatusUseCase _getSessionStatus;
  final GetActiveSessionUseCase _getActiveSession;
  final HomeBloc _homeBloc;
  final SocketService _socketService;
  final StorageService _storage;
  final LocationService _locationService;

  Timer? _tickTimer;
  int _secondsRemaining = AppConstants.sessionAutoCloseSeconds;
  String? _restoringUserId;
  int _recoveryGeneration = 0;
  bool _openScannerAfterRecovery = false;
  bool _syncingStatus = false;

  RecyclingBloc({
    required StartSessionUseCase startSession,
    required StartManualSessionUseCase startManualSession,
    required EndSessionUseCase endSession,
    required GetSessionStatusUseCase getSessionStatus,
    required GetActiveSessionUseCase getActiveSession,
    required HomeBloc homeBloc,
    required SocketService socketService,
    required StorageService storage,
    required LocationService locationService,
  })  : _startSession = startSession,
        _startManualSession = startManualSession,
        _endSession = endSession,
        _getSessionStatus = getSessionStatus,
        _getActiveSession = getActiveSession,
        _homeBloc = homeBloc,
        _socketService = socketService,
        _storage = storage,
        _locationService = locationService,
        super(RecyclingIdle()) {
    on<RecyclingQrScannedEvent>(_onQrScanned);
    on<RecyclingManualCodeSubmitted>(_onManualCodeSubmitted);
    on<RecyclingFinishSessionEvent>(_onFinishSession);
    on<RecyclingWsSessionUpdateEvent>(_onWsSessionUpdate);
    on<RecyclingTimerTickEvent>(_onTimerTick);
    on<RecyclingSyncSessionEvent>(_onSyncSession);
    on<RecyclingLocalTimeoutEvent>(_onLocalTimeout);
    on<RecyclingClearRejectionEvent>(_onClearRejection);
    on<RecyclingRestoreSessionEvent>(_onRestoreSession);
    on<RecyclingResetEvent>((event, emit) {
      _recoveryGeneration++;
      _restoringUserId = null;
      _openScannerAfterRecovery = false;
      _cancelLocalTimer();
      _socketService.disconnect();
      emit(RecyclingIdle());
    });
  }

  Future<void> _onRestoreSession(
    RecyclingRestoreSessionEvent event,
    Emitter<RecyclingState> emit,
  ) async {
    if (_restoringUserId == event.userId) {
      _openScannerAfterRecovery |= event.openScanner;
      return;
    }

    final current = state;
    if (current is RecyclingConnecting ||
        (current is RecyclingSessionActive && !event.openScanner)) {
      return;
    }

    final generation = ++_recoveryGeneration;
    _restoringUserId = event.userId;
    _openScannerAfterRecovery = event.openScanner;
    if (current is RecyclingSessionActive) {
      _cancelLocalTimer();
      _socketService.disconnect();
    }
    emit(RecyclingCheckingSession());

    bool isCurrent() => _recoveryGeneration == generation && !emit.isDone;

    void showRetry(String message) {
      if (!isCurrent()) return;
      emit(RecyclingRecoveryPending(
        event.userId,
        message,
        openScanner: _openScannerAfterRecovery,
      ));
    }

    void showReady() {
      if (!isCurrent()) return;
      emit(_openScannerAfterRecovery ? RecyclingReadyToScan() : RecyclingIdle());
    }

    Future<void> resume(RecyclingSessionSnapshot snapshot) async {
      if (_remainingFor(snapshot) <= 0) {
        showRetry('La sesión llegó a su límite. Vuelve a consultar su estado.');
        return;
      }
      await _rememberRecoveredSession(snapshot.sessionId, event.userId);
      if (isCurrent()) _resumeSnapshot(snapshot, event.userId, emit);
    }

    try {
      final result = await _getActiveSession();
      if (!isCurrent()) return;
      await result.fold<Future<void>>(
        (failure) async => showRetry('No se pudo verificar la sesión: ${failure.message}'),
        (active) async {
          if (active != null) {
            await resume(active);
            return;
          }

          final savedId = await _readSavedSessionId(event.userId);
          if (!isCurrent()) return;
          if (savedId == null) {
            showReady();
            return;
          }

          final savedResult = await _getSessionStatus(savedId);
          if (!isCurrent()) return;
          await savedResult.fold<Future<void>>(
            (failure) async {
              if (failure is NotFoundFailure || failure is ValidationFailure) {
                await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
                showReady();
              } else {
                showRetry('No se pudo verificar la sesión anterior: ${failure.message}');
              }
            },
            (snapshot) async {
              if (snapshot.isActive) {
                await resume(snapshot);
                return;
              }
              await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
              if (!isCurrent()) return;
              _homeBloc.add(HomeRefreshEvent());
              emit(RecyclingSessionCompleted(
                session: _toRecyclingSession(snapshot),
                autoClosed: snapshot.status == 'EXPIRED',
              ));
            },
          );
        },
      );
    } catch (_) {
      showRetry('No se pudo verificar la sesión anterior.');
    } finally {
      if (_recoveryGeneration == generation) {
        _restoringUserId = null;
        _openScannerAfterRecovery = false;
      }
    }
  }

  Future<String?> _readSavedSessionId(String userId) async {
    final raw = await _storage.read(key: AppConstants.activeRecyclingSessionKey);
    if (raw == null) return null;
    try {
      final saved = jsonDecode(raw);
      if (saved is Map<String, dynamic> && saved['userId'] == userId) {
        final sessionId = saved['sessionId'];
        return sessionId is String && sessionId.isNotEmpty ? sessionId : null;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  int _remainingFor(RecyclingSessionSnapshot snapshot) =>
      snapshot.remainingSeconds ??
      (snapshot.expiresAt?.difference(DateTime.now()).inSeconds ?? 0);

  RecyclingSession _toRecyclingSession(RecyclingSessionSnapshot snapshot) =>
      RecyclingSession(
        sessionId: snapshot.sessionId,
        binId: snapshot.smartBinId,
        locationName: snapshot.locationName ?? 'Punto RecySmart',
        bottlesDropped: snapshot.bottlesAccepted,
        pointsEarned: snapshot.pointsCalculated,
        co2Saved: snapshot.bottlesAccepted * 0.04,
      );

  void _resumeSnapshot(
    RecyclingSessionSnapshot snapshot,
    String userId,
    Emitter<RecyclingState> emit,
  ) {
    final session = _toRecyclingSession(snapshot);
    _connectSocket(session.sessionId, userId);
    _startLocalTimer(_remainingFor(snapshot));
    emit(RecyclingSessionActive(
      session: session,
      timerSeconds: _secondsRemaining,
      recovered: true,
    ));
  }

  Future<void> _rememberRecoveredSession(String sessionId, String userId) async {
    try {
      await _storage.write(
        key: AppConstants.activeRecyclingSessionKey,
        value: jsonEncode({'userId': userId, 'sessionId': sessionId}),
      );
    } catch (_) {
      debugPrint('No se pudo guardar la referencia de la sesión recuperada.');
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
      onReconnected: () {
        if (!isClosed) add(RecyclingSyncSessionEvent());
      },
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
    if (state is RecyclingConnecting || state is RecyclingSessionActive) return;
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
          (session) => _activateStartedSession(session, userId, emit),
    );
  }

  Future<void> _onManualCodeSubmitted(
    RecyclingManualCodeSubmitted event,
    Emitter<RecyclingState> emit,
  ) async {
    if (state is RecyclingConnecting || state is RecyclingSessionActive) return;
    final code = event.code.trim();
    if (code.isEmpty || code.length > 128) {
      emit(const RecyclingManualStartFailed('Ingresa un código válido.'));
      return;
    }

    emit(RecyclingConnecting());
    final generation = _recoveryGeneration;
    bool isCurrent() => generation == _recoveryGeneration && !emit.isDone;
    try {
      final userId = await _storage.read(key: AppConstants.userIdKey);
      if (!isCurrent()) return;
      if (userId == null || userId.isEmpty) {
        emit(const RecyclingManualStartFailed('Vuelve a iniciar sesión.'));
        return;
      }

      final position = await _locationService.getCurrentPosition();
      if (!isCurrent()) return;
      final result = await _startManualSession(
        qrToken: code,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!isCurrent()) return;
      await result.fold<Future<void>>(
        (failure) async => emit(RecyclingManualStartFailed(failure.message)),
        (session) => _activateStartedSession(session, userId, emit),
      );
    } on TimeoutException {
      if (isCurrent()) {
        emit(const RecyclingManualStartFailed(
          'No se pudo obtener tu ubicación. Intenta nuevamente.',
        ));
      }
    } catch (error) {
      if (isCurrent()) {
        emit(RecyclingManualStartFailed(
          error.toString().replaceFirst('Exception: ', ''),
        ));
      }
    }
  }

  Future<void> _activateStartedSession(
    RecyclingSession session,
    String userId,
    Emitter<RecyclingState> emit,
  ) async {
    final generation = _recoveryGeneration;
    await _rememberRecoveredSession(session.sessionId, userId);
    if (emit.isDone || generation != _recoveryGeneration) return;
    _connectSocket(session.sessionId, userId);
    _startLocalTimer(session.timeoutSeconds ?? AppConstants.sessionAutoCloseSeconds);
    emit(RecyclingSessionActive(session: session, timerSeconds: _secondsRemaining));
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

  Future<void> _onSyncSession(
      RecyclingSyncSessionEvent event, Emitter<RecyclingState> emit) async {
    if (_syncingStatus || state is! RecyclingSessionActive ||
        (state as RecyclingSessionActive).isEnding) {
      return;
    }
    _syncingStatus = true;
    final sessionId = (state as RecyclingSessionActive).session.sessionId;
    try {
      final result = await _getSessionStatus(sessionId);
      final snapshot = result.fold<RecyclingSessionSnapshot?>(
        (_) => null,
        (value) => value,
      );
      if (snapshot == null || state is! RecyclingSessionActive) return;
      final active = state as RecyclingSessionActive;
      if (active.session.sessionId != sessionId || active.isEnding) return;

      if (!snapshot.isActive) {
        await _storage.delete(key: AppConstants.activeRecyclingSessionKey);
        _cancelLocalTimer();
        _socketService.disconnect();
        _homeBloc.add(HomeRefreshEvent());
        emit(RecyclingSessionCompleted(
          session: active.session.copyWith(
            bottlesDropped: snapshot.bottlesAccepted,
            pointsEarned: snapshot.pointsCalculated,
            co2Saved: snapshot.bottlesAccepted * 0.04,
          ),
          autoClosed: snapshot.status == 'EXPIRED',
        ));
        return;
      }

      final seconds = _remainingFor(snapshot);
      if (seconds > 0) {
        if (_tickTimer?.isActive == true) {
          _resetLocalTimer(seconds);
        } else {
          _startLocalTimer(seconds);
        }
      }
      if (active.session.bottlesDropped != snapshot.bottlesAccepted ||
          active.session.pointsEarned != snapshot.pointsCalculated ||
          active.timerSeconds != _secondsRemaining) {
        emit(RecyclingSessionActive(
          session: active.session.copyWith(
            bottlesDropped: snapshot.bottlesAccepted,
            pointsEarned: snapshot.pointsCalculated,
            co2Saved: snapshot.bottlesAccepted * 0.04,
          ),
          timerSeconds: _secondsRemaining,
          bottleRejected: active.bottleRejected,
          bottleError: active.bottleError,
          rejectionCount: active.rejectionCount,
          recovered: active.recovered,
        ));
      }
    } catch (error) {
      debugPrint('No se pudo sincronizar la sesión $sessionId: $error');
    } finally {
      _syncingStatus = false;
    }
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
        if (!isClosed) {
          add(RecyclingTimerTickEvent(_secondsRemaining));
          if (_secondsRemaining % 5 == 0) add(RecyclingSyncSessionEvent());
        }
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
