import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recysmart/features/home/data/models/home_data_model.dart';
import 'package:recysmart/features/home/presentation/pages/home_page.dart';
import 'package:recysmart/features/levels/domain/entities/level.dart';

void main() {
  const levels = [
    Level(id: '3', name: 'Green Warrior', minPointsRequired: 500),
    Level(id: '1', name: 'Eco Beginner', minPointsRequired: 0),
    Level(id: '2', name: 'Recycler Apprentice', minPointsRequired: 100),
  ];

  HomeDataModel wallet(int balance, int lifetime) =>
      HomeDataModel.fromProfileAndTransactions({
        'wallet': {'currentBalance': balance, 'lifetimeEarned': lifetime},
      }, const [], levels: levels);

  test('spending points does not change level progression', () {
    final before = wallet(200, 300);
    final after = wallet(20, 300);
    expect(after.totalPoints, 20);
    expect(after.levelProgress, before.levelProgress);
    expect(after.levelProgress?.current.name, 'Recycler Apprentice');
    expect(after.levelProgress?.next?.name, 'Green Warrior');
    expect(after.levelProgress?.pointsRemaining, 200);
    expect(after.levelProgress?.fraction, 0.5);
  });

  test('missing levels do not imply a maximum level', () {
    final data = HomeDataModel.fromProfileAndTransactions(const {
      'wallet': {'currentBalance': 20, 'lifetimeEarned': 300},
    }, const []);
    expect(data.levelProgress, isNull);
  });

  testWidgets('renders progress and the next level on Home', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: HomeLevelProgressIndicator(progress: wallet(20, 300).levelProgress),
    )));
    expect(find.text('Recycler Apprentice'), findsOneWidget);
    expect(find.text('300 EcoPuntos acumulados'), findsOneWidget);
    expect(find.text('Faltan 200 EcoPuntos para Green Warrior'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    ).value, 0.5);

    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: HomeLevelProgressIndicator(progress: wallet(20, 500).levelProgress),
    )));
    expect(find.text('Nivel máximo alcanzado'), findsOneWidget);
  });
}
