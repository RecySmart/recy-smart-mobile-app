import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../network/api_client.dart';
import 'storage_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
as auth_ds;
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Home
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data_usecase.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

// Recycling
import '../../features/recycling/data/datasources/recycling_remote_datasource.dart';
import '../../features/recycling/data/repositories/recycling_repository_impl.dart';
import '../../features/recycling/domain/repositories/recycling_repository.dart';
import '../../features/recycling/domain/usecases/start_session_usecase.dart';
import '../../features/recycling/presentation/bloc/recycling_bloc.dart';

// Rewards
import '../../features/rewards/data/datasources/rewards_remote_datasource.dart';
import '../../features/rewards/data/repositories/rewards_repository_impl.dart';
import '../../features/rewards/domain/repositories/rewards_repository.dart';
import '../../features/rewards/domain/usecases/get_active_rewards_usecase.dart';
import '../../features/rewards/presentation/bloc/rewards_bloc.dart';

// Profile
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_transaction_history_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// Map
import '../../features/map/data/datasources/map_remote_datasource.dart';
import '../../features/map/data/repositories/map_repository_impl.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../features/map/domain/usecases/get_all_bins_usecase.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── External ─────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  FlutterSecureStorage? secureStorage;
  if (!kIsWeb) {
    secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage!);
  }

  // ── Unified Storage ───────────────────────────────────────────────────────
  sl.registerLazySingleton<StorageService>(
        () => StorageService(
      secure: kIsWeb ? null : secureStorage,
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(
        () => ApiClient(
      secureStorage: kIsWeb ? null : secureStorage,
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<auth_ds.AuthRemoteDataSource>(
        () => auth_ds.AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<auth_ds.AuthRemoteDataSource>(), sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(
        () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      getProfileUseCase: sl(),
      logoutUseCase: sl(),
      storageService: sl(),
    ),
  );

  // ── Home ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeRemoteDataSource>(
        () => HomeRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => HomeBloc(sl()));

  // ── Recycling ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<RecyclingRemoteDataSource>(
        () => RecyclingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<RecyclingRepository>(
        () => RecyclingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => StartSessionUseCase(sl()));
  sl.registerLazySingleton(
        () => RecyclingBloc(sl<StartSessionUseCase>(), sl<HomeBloc>()),
  );

  // ── Rewards ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<RewardsRemoteDataSource>(
        () => RewardsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<RewardsRepository>(
        () => RewardsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetActiveRewardsUseCase(sl()));
  sl.registerLazySingleton(() => RedeemRewardUseCase(sl()));
  sl.registerLazySingleton(() => GetMyCouponsUseCase(sl()));
  sl.registerFactory(
        () => RewardsBloc(
      sl<GetActiveRewardsUseCase>(),
      sl<RedeemRewardUseCase>(),
      sl<GetMyCouponsUseCase>(),
    ),
  );

  // ── Profile ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetTransactionHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAchievementsUseCase(sl()));
  sl.registerFactory(
        () => ProfileBloc(
      sl<GetTransactionHistoryUseCase>(),
      sl<GetAchievementsUseCase>(),
      sl<AuthBloc>(),
    ),
  );

  // ── Map ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MapRemoteDataSource>(
        () => MapRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<MapRepository>(() => MapRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAllBinsUseCase(sl()));
  sl.registerFactory(() => MapBloc(sl()));
}