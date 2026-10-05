import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recysmart/core/errors/failures.dart';
import 'package:recysmart/core/utils/injection_container.dart';
import 'package:recysmart/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:recysmart/features/profile/domain/usecases/get_transaction_history_usecase.dart';
import 'package:recysmart/features/recycling/domain/entities/recycling_session.dart';
import 'package:recysmart/features/recycling/domain/usecases/start_session_usecase.dart';
import 'package:recysmart/features/recycling/presentation/pages/session_summary_page.dart';

class MockStatusUseCase extends Mock implements GetSessionStatusUseCase {}
class MockHistoryUseCase extends Mock implements GetTransactionHistoryUseCase {}
class MockProfileUseCase extends Mock implements GetProfileUseCase {}

void main() {
  testWidgets('el resumen usa el recuento del servidor aunque el socket perdió el evento',
      (tester) async {
    final status = MockStatusUseCase();
    final history = MockHistoryUseCase();
    final profile = MockProfileUseCase();
    sl.registerSingleton<GetSessionStatusUseCase>(status);
    sl.registerSingleton<GetTransactionHistoryUseCase>(history);
    sl.registerSingleton<GetProfileUseCase>(profile);
    addTearDown(() async => sl.reset());

    when(() => status('session-1')).thenAnswer((_) async => const Right(
      RecyclingSessionSnapshot(
        sessionId: 'session-1', smartBinId: 'bin-1', status: 'COMPLETED',
        bottlesAccepted: 1, pointsCalculated: 10,
      ),
    ));
    when(() => history()).thenAnswer(
        (_) async => const Left(ServerFailure('Sin historial')));
    when(() => profile()).thenAnswer(
        (_) async => const Left(ServerFailure('Sin perfil')));

    await tester.pumpWidget(const MaterialApp(
      home: SessionSummaryPage(
        sessionId: 'session-1', bottlesDropped: 0, pointsEarned: 0,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('+0'), findsNothing);
  });
}
