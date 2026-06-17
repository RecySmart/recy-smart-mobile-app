import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthTokens>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> getProfile();

  Future<Either<Failure, void>> logout();

  Future<bool> isLoggedIn();
}