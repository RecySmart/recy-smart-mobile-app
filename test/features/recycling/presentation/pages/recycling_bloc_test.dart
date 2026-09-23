import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recysmart/core/errors/failures.dart';
import 'package:recysmart/core/constants/app_constants.dart';
import 'package:recysmart/core/services/location_service.dart';
import 'package:recysmart/core/services/socket_service.dart';
import 'package:recysmart/core/utils/storage_service.dart';
import 'package:recysmart/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:recysmart/features/home/presentation/bloc/home_bloc.dart';
import 'package:recysmart/features/recycling/domain/entities/recycling_session.dart';
import 'package:recysmart/features/recycling/domain/usecases/start_session_usecase.dart';
import 'package:recysmart/features/recycling/presentation/bloc/recycling_bloc.dart';

class MockStartSessionUseCase extends Mock implements StartSessionUseCase {}
class MockEndSessionUseCase extends Mock implements EndSessionUseCase {}
class MockGetSessionStatusUseCase extends Mock implements GetSessionStatusUseCase {}
class MockStorageService extends Mock implements StorageService {}
class MockLocationService extends Mock implements LocationService {}
class MockPosition extends Mock implements Position {}
class MockSocketService extends Mock implements SocketService {}
class MockGetHomeDataUseCase extends Mock implements GetHomeDataUseCase {}

class TestHomeBloc extends HomeBloc {
  TestHomeBloc() : super(MockGetHomeDataUseCase());

  @override
  void add(HomeEvent event) {}
}

void main() {
  late MockStartSessionUseCase start;
  late MockEndSessionUseCase end;
  late MockGetSessionStatusUseCase status;
  late MockStorageService storage;
  late MockLocationService location;
  late MockSocketService socket;
  late TestHomeBloc home;
  late RecyclingBloc bloc;

  setUp(() {
    start = MockStartSessionUseCase();
    end = MockEndSessionUseCase();
    status = MockGetSessionStatusUseCase();
    storage = MockStorageService();
    location = MockLocationService();
    socket = MockSocketService();
    home = TestHomeBloc();

    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'user-1');
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
    when(() => location.getCurrentPosition())
        .thenAnswer((_) async => MockPosition());
    when(() => socket.connect(
          sessionId: any(named: 'sessionId'),
          userId: any(named: 'userId'),
          onSessionUpdate: any(named: 'onSessionUpdate'),
          onPointsUpdate: any(named: 'onPointsUpdate'),
          onAchievementUnlocked: any(named: 'onAchievementUnlocked'),
        )).thenAnswer((_) async {});
    when(() => start(
          userId: any(named: 'userId'),
          smartBinId: any(named: 'smartBinId'),
          qrToken: any(named: 'qrToken'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async => const Right(RecyclingSession(
          sessionId: 'session-1',
          binId: 'bin-1',
          locationName: 'Punto de prueba',
        )));

    bloc = RecyclingBloc(
      startSession: start,
      endSession: end,
      getSessionStatus: status,
      homeBloc: home,
      socketService: socket,
      storage: storage,
      locationService: location,
    );
  });

  tearDown(() async {
    await bloc.close();
    await home.close();
  });

  Future<void> startDemoSession() async {
    final active = bloc.stream.firstWhere((s) => s is RecyclingSessionActive);
    bloc.add(const RecyclingQrScannedEvent(
      '{"smartBinId":"bin-1","qrToken":"token-1","latitude":-12.1,"longitude":-77.1}',
    ));
    await active;
  }

  test('demo session sends QR coordinates, not device coordinates', () async {
    await startDemoSession();
    verify(() => location.getCurrentPosition()).called(1);
    verify(() => start(
          userId: 'user-1',
          smartBinId: 'bin-1',
          qrToken: 'token-1',
          latitude: -12.1,
          longitude: -77.1,
        )).called(1);
  });

  test('denied location permission stops the demo before session start', () async {
    when(() => location.getCurrentPosition())
        .thenThrow(Exception('Los permisos de ubicación fueron denegados.'));
    final error = bloc.stream.firstWhere((s) => s is RecyclingError);
    bloc.add(const RecyclingQrScannedEvent(
      '{"smartBinId":"bin-1","qrToken":"token-1","latitude":-12.1,"longitude":-77.1}',
    ));
    await error;
    verifyNever(() => start(
          userId: any(named: 'userId'),
          smartBinId: any(named: 'smartBinId'),
          qrToken: any(named: 'qrToken'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ));
  });

  test('local timeout retains session for retry when close fails', () async {
    when(() => end('session-1'))
        .thenAnswer((_) async => const Left(ServerFailure('500')));
    await startDemoSession();

    final failure = bloc.stream.firstWhere((s) => s is RecyclingEndSessionFailed);
    bloc.add(RecyclingLocalTimeoutEvent());
    await failure;
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<RecyclingSessionActive>());
    expect((bloc.state as RecyclingSessionActive).timerSeconds, 0);
    verify(() => end('session-1')).called(1);
  });

  test('local timeout completes only after remote close succeeds', () async {
    when(() => end('session-1')).thenAnswer((_) async => const Right(null));
    await startDemoSession();

    final completed = bloc.stream.firstWhere((s) => s is RecyclingSessionCompleted);
    bloc.add(RecyclingLocalTimeoutEvent());
    await completed;

    expect((bloc.state as RecyclingSessionCompleted).autoClosed, isTrue);
    verify(() => end('session-1')).called(1);
  });

  test('lost close response reconciles terminal server status', () async {
    when(() => end('session-1'))
        .thenAnswer((_) async => const Left(ServerFailure('socket cut')));
    when(() => status('session-1')).thenAnswer((_) async => const Right(
      RecyclingSessionSnapshot(
        sessionId: 'session-1', smartBinId: 'bin-1', status: 'COMPLETED',
        bottlesAccepted: 3, pointsCalculated: 30,
      ),
    ));
    await startDemoSession();
    final completed = bloc.stream.firstWhere((s) => s is RecyclingSessionCompleted);
    bloc.add(RecyclingFinishSessionEvent());
    final result = await completed as RecyclingSessionCompleted;
    expect(result.session.bottlesDropped, 3);
    expect(result.session.pointsEarned, 30);
    verify(() => status('session-1')).called(1);
  });

  test('restores active server session after restart', () async {
    when(() => storage.read(key: AppConstants.activeRecyclingSessionKey))
        .thenAnswer((_) async => '{"userId":"user-1","sessionId":"session-1"}');
    when(() => status('session-1')).thenAnswer((_) async => Right(
      RecyclingSessionSnapshot(
        sessionId: 'session-1', smartBinId: 'bin-1', status: 'IN_PROGRESS',
        bottlesAccepted: 2, pointsCalculated: 20,
        expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      ),
    ));
    final restored = bloc.stream.firstWhere((s) =>
        s is RecyclingSessionActive && s.recovered);
    bloc.add(const RecyclingRestoreSessionEvent('user-1'));
    final state = await restored as RecyclingSessionActive;
    expect(state.session.bottlesDropped, 2);
    expect(state.session.pointsEarned, 20);
    verify(() => status('session-1')).called(1);
  });

  test('keeps recovery token when status query fails', () async {
    when(() => storage.read(key: AppConstants.activeRecyclingSessionKey))
        .thenAnswer((_) async => '{"userId":"user-1","sessionId":"session-1"}');
    when(() => status('session-1'))
        .thenAnswer((_) async => const Left(ServerFailure('offline')));
    final pending = bloc.stream.firstWhere((s) => s is RecyclingRecoveryPending);
    bloc.add(const RecyclingRestoreSessionEvent('user-1'));
    await pending;
    verifyNever(() => storage.delete(key: AppConstants.activeRecyclingSessionKey));
  });
}
