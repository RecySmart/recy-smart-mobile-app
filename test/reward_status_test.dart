import 'package:flutter_test/flutter_test.dart';
import 'package:recysmart/features/rewards/domain/entities/reward.dart';

void main() {
  const base = Reward(
    id: 'reward-1', companyId: 'company-1', companyName: 'Aliado',
    title: 'Premio', description: 'Descripción', costInPoints: 10,
    remainingStock: 2, status: 'ACTIVE',
  );

  test('available reward can be redeemed', () {
    expect(base.isAvailable, isTrue);
    expect(base.availabilityLabel, 'Canjear Premio');
  });

  test('out-of-stock reward is blocked and labeled', () {
    const reward = Reward(
      id: 'reward-2', companyId: 'company-1', companyName: 'Aliado',
      title: 'Premio', description: 'Descripción', costInPoints: 10,
      remainingStock: 0, status: 'OUT_OF_STOCK',
    );
    expect(reward.isAvailable, isFalse);
    expect(reward.availabilityLabel, 'Agotado');
  });

  test('discontinued reward is shown as paused and blocked', () {
    const reward = Reward(
      id: 'reward-3', companyId: 'company-1', companyName: 'Aliado',
      title: 'Premio', description: 'Descripción', costInPoints: 10,
      remainingStock: 2, status: 'DISCONTINUED',
    );
    expect(reward.isAvailable, isFalse);
    expect(reward.availabilityLabel, 'Pausado');
  });

  test('expired reward is blocked even with stock', () {
    const reward = Reward(
      id: 'reward-4', companyId: 'company-1', companyName: 'Aliado',
      title: 'Premio', description: 'Descripción', costInPoints: 10,
      remainingStock: 2, status: 'ACTIVE', expiresAt: '2020-01-01T00:00:00Z',
    );
    expect(reward.isAvailable, isFalse);
    expect(reward.availabilityLabel, 'Vencido');
  });
}
