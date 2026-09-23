import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a Internet. Revisa tu red e inténtalo de nuevo.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Tu sesión expiró. Inicia sesión de nuevo.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No se pudieron leer los datos locales. Inténtalo de nuevo.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
