import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../domain/usecases/get_transaction_history_usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object> get props => [];
}

class ProfileLoadTransactionsEvent extends ProfileEvent {}
class ProfileLoadAchievementsEvent extends ProfileEvent {}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}

class ProfileTransactionsLoaded extends ProfileState {
  final List<TransactionModel> transactions;
  const ProfileTransactionsLoaded(this.transactions);
  @override
  List<Object> get props => [transactions];
}

class ProfileAchievementsLoaded extends ProfileState {
  final List<AchievementModel> achievements;
  const ProfileAchievementsLoaded(this.achievements);
  @override
  List<Object> get props => [achievements];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetTransactionHistoryUseCase _getTransactions;
  final GetAchievementsUseCase _getAchievements;
  final AuthBloc _authBloc;

  ProfileBloc(this._getTransactions, this._getAchievements, this._authBloc)
      : super(ProfileInitial()) {
    on<ProfileLoadTransactionsEvent>(_onLoadTransactions);
    on<ProfileLoadAchievementsEvent>(_onLoadAchievements);
  }

  Future<void> _onLoadTransactions(
      ProfileLoadTransactionsEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await _getTransactions();
    result.fold(
          (f) => emit(ProfileError(f.message)),
          (data) => emit(ProfileTransactionsLoaded(data)),
    );
  }

  Future<void> _onLoadAchievements(
      ProfileLoadAchievementsEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await _getAchievements();
    result.fold(
          (f) => emit(ProfileError(f.message)),
          (data) => emit(ProfileAchievementsLoaded(data)),
    );
  }
}