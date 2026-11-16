import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recysmart/features/recycling/domain/entities/recycling_session.dart';
import 'package:recysmart/features/recycling/presentation/bloc/recycling_bloc.dart';
import 'package:recysmart/features/recycling/presentation/pages/qr_scanner_page.dart';

class FakeRecyclingBloc extends MockBloc<RecyclingEvent, RecyclingState>
    implements RecyclingBloc {}

void main() {
  testWidgets('keeps the manual code after rejection and closes after success',
      (tester) async {
    final bloc = FakeRecyclingBloc();
    final states = StreamController<RecyclingState>.broadcast();
    addTearDown(states.close);
    whenListen(bloc, states.stream, initialState: RecyclingIdle());
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<RecyclingBloc>.value(
        value: bloc,
        child: Builder(builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BlocProvider<RecyclingBloc>.value(
                  value: bloc,
                  child: const ManualCodeSheet(),
                ),
              );
              if (context.mounted && result == true) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Sesión abierta')));
              }
            },
            child: const Text('Abrir código manual'),
          ),
        )),
      ),
    ));
    await tester.tap(find.text('Abrir código manual'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'recysmart-code');
    await tester.tap(find.text('Conectar al punto'));
    await tester.pumpAndSettle();
    expect(find.text('Conectando con el punto…'), findsOneWidget);
    states.add(const RecyclingManualStartFailed('El punto está ocupado.'));
    await tester.pumpAndSettle();
    expect(find.text('El punto está ocupado.'), findsOneWidget);
    expect(find.text('recysmart-code'), findsOneWidget);

    await tester.tap(find.text('Conectar al punto'));
    await tester.pumpAndSettle();
    states.add(const RecyclingSessionActive(
      session: RecyclingSession(
        sessionId: 'session-1', binId: 'bin-1', locationName: 'Punto QA',
      ),
      timerSeconds: 180,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ManualCodeSheet), findsNothing);
    expect(find.text('Sesión abierta'), findsOneWidget);
    verify(() => bloc.add(const RecyclingManualCodeSubmitted('recysmart-code')))
        .called(2);
  });
}
