import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recysmart/core/constants/app_constants.dart';
import 'package:recysmart/core/network/api_client.dart';
import 'package:recysmart/features/rewards/data/datasources/rewards_remote_datasource.dart';
import 'package:recysmart/features/rewards/data/models/reward_model.dart';
import 'package:recysmart/features/rewards/domain/entities/reward.dart';

class MockCatalogApi extends Mock implements ApiClient {}

void main() {
  test('loads later catalog pages and merges repeated reward IDs', () async {
    final api = MockCatalogApi();
    final dataSource = RewardsRemoteDataSourceImpl(api);
    const path = AppConstants.rewardsCatalogEndpoint;

    Map<String, dynamic> item(int id) => {
          'id': 'reward-$id',
          'title': 'Premio',
          'description': 'Descripción',
          'costInPoints': 10,
          'remainingStock': 2,
          'status': 'ACTIVE',
        };

    for (final page in [1, 2]) {
      when(() => api.get(path, queryParameters: {'page': page, 'limit': 100}))
          .thenAnswer((_) async => Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                data: page == 1 ? List.generate(100, item) : [item(99), item(100)],
              ));
    }

    final catalog = await dataSource.getActiveRewards();
    expect(catalog, hasLength(101));
    expect(catalog.last.id, 'reward-100');
  });

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

  test('server availability can block an otherwise active catalog entry', () {
    final reward = RewardModel.fromJson(const {
      'id': 'reward-5',
      'title': 'Premio',
      'description': 'Descripción',
      'costInPoints': 10,
      'remainingStock': 2,
      'status': 'ACTIVE',
      'availabilityStatus': 'EXPIRED',
    });

    expect(reward.status, 'ACTIVE');
    expect(reward.availabilityLabel, 'Vencido');
    expect(reward.isAvailable, isFalse);
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
