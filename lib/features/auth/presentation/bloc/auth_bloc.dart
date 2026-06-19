import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}
class AuthGetProfileEvent extends AuthEvent {}
class AuthLogoutEvent extends AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthRegisterEvent({
    required this.name,
    required this.email,
    required this.password,
  });
  @override
  List<Object> get props => [name, email, password];
}

// Internal — fired by Dio interceptor on 401
class AuthSessionExpiredEvent extends AuthEvent {}

// ── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthSessionExpired extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetProfileUseCase getProfileUseCase;
  final LogoutUseCase logoutUseCase;
  final StorageService storageService;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getProfileUseCase,
    required this.logoutUseCase,
    required this.storageService,
  }) : super(AuthInitial()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthGetProfileEvent>(_onGetProfile);
    on<AuthSessionExpiredEvent>(_onSessionExpired);
  }

  Future<void> _onCheckStatus(
      AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final token = await storageService.read(key: AppConstants.accessTokenKey);
    if (token == null || token.isEmpty) {
      emit(AuthUnauthenticated());
      return;
    }
    // Token exists — fetch fresh profile with wallet
    final result = await getProfileUseCase();
    result.fold(
          (failure) {
        // 401 = token expired → show session expired state
        if (failure.message.contains('expired') ||
            failure.message.contains('Session') ||
            failure.message.contains('401')) {
          emit(AuthSessionExpired());
        } else {
          // Other error (network) → still consider authenticated with cached data
          emit(AuthUnauthenticated());
        }
      },
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result =
    await loginUseCase(email: event.email, password: event.password);
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (tokens) => emit(AuthAuthenticated(tokens.user)),
    );
  }

  Future<void> _onRegister(
      AuthRegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      name: event.name,
      email: event.email,
      password: event.password,
    );
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (tokens) => emit(AuthAuthenticated(tokens.user)),
    );
  }

  Future<void> _onLogout(
      AuthLogoutEvent event, Emitter<AuthState> emit) async {
    await logoutUseCase();
    emit(AuthUnauthenticated());
  }

  Future<void> _onGetProfile(
      AuthGetProfileEvent event, Emitter<AuthState> emit) async {
    // Don't show loading — silent refresh in background
    final result = await getProfileUseCase();
    result.fold(
          (failure) {
        if (failure.message.contains('expired') ||
            failure.message.contains('Session') ||
            failure.message.contains('401')) {
          emit(AuthSessionExpired());
        }
        // Otherwise keep current state
      },
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSessionExpired(
      AuthSessionExpiredEvent event, Emitter<AuthState> emit) async {
    await storageService.deleteAll();
    emit(AuthSessionExpired());
  }
}