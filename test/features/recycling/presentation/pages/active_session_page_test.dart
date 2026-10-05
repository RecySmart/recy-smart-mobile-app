import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recysmart/core/utils/app_router.dart';
import 'package:recysmart/features/recycling/domain/entities/recycling_session.dart';
import 'package:recysmart/features/recycling/presentation/bloc/recycling_bloc.dart';
import 'package:recysmart/features/recycling/presentation/pages/active_session_page.dart';

class MockRecyclingBloc extends MockBloc<RecyclingEvent, RecyclingState>
    implements RecyclingBloc {}

void main() {
  testWidgets('el cierre conserva sessionId y el botón tiene texto visible',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const session = RecyclingSession(
      sessionId: 'session-123',
      binId: 'bin-123',
      locationName: 'Punto de prueba',
    );
    final bloc = MockRecyclingBloc();
    final states = StreamController<RecyclingState>();
    addTearDown(states.close);
    whenListen(
      bloc,
      states.stream,
      initialState: const RecyclingSessionActive(
        session: session,
        timerSeconds: 60,
      ),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.activeSession,
      routes: [
        GoRoute(
          path: AppRoutes.activeSession,
          builder: (_, __) => BlocProvider<RecyclingBloc>.value(
            value: bloc,
            child: const ActiveSessionPage(
              binId: 'bin-123',
              locationName: 'Punto de prueba',
              sessionId: 'session-123',
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.sessionSummary,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>;
            return Scaffold(body: Text(extra['sessionId'] as String));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.style?.foregroundColor?.resolve({}), Colors.white);
    expect(find.text('Finalizar Sesión'), findsOneWidget);

    states.add(const RecyclingSessionCompleted(session: session));
    await tester.pumpAndSettle();
    expect(find.text('session-123'), findsOneWidget);
  });
}
