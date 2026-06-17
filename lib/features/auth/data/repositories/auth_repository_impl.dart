import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storage;

  AuthRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result =
      await _remoteDataSource.login(email: email, password: password);
      await _saveSession(result.token, result.user);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );
      await _saveSession(result.token, result.user);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final user = await _remoteDataSource.getProfile();
      return Right(user);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _storage.deleteAll();
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveSession(String token, User user) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: token),
      _storage.write(key: AppConstants.userIdKey, value: user.id),
      _storage.write(key: AppConstants.userRoleKey, value: user.role),
      _storage.write(key: AppConstants.userNameKey, value: user.name),
      _storage.write(key: AppConstants.userEmailKey, value: user.email),
    ]);
  }
}