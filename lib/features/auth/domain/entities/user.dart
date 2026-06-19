import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final Wallet? wallet;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.wallet,
  });

  bool get isRecycler => role == 'RECYCLER';
  bool get isAlly => role == 'ALLY';
  bool get isAdmin => role == 'ADMIN';

  @override
  List<Object?> get props => [id, name, email, role, wallet];
}

class Wallet extends Equatable {
  final String id;          // may be a local fallback string if backend omits it
  final int currentBalance;
  final int lifetimeEarned;
  final int totalBottles;
  final double totalWeight;
  final double weight;
  final double co2Saved;
  final WalletLevel? level;

  const Wallet({
    this.id = 'wallet-local',   // default so subclasses don't need to pass it
    required this.currentBalance,
    required this.lifetimeEarned,
    required this.totalBottles,
    required this.totalWeight,
    required this.weight,
    required this.co2Saved,
    this.level,
  });

  @override
  List<Object?> get props => [
    id,
    currentBalance,
    lifetimeEarned,
    totalBottles,
    totalWeight,
    weight,
    co2Saved,
    level,
  ];
}

class WalletLevel extends Equatable {
  final String id;                  // optional — backend may omit
  final String name;
  final int minPointsRequired;

  const WalletLevel({
    this.id = 'level-local',
    required this.name,
    this.minPointsRequired = 0,
  });

  @override
  List<Object> get props => [id, name, minPointsRequired];
}

class AuthTokens extends Equatable {
  final String token;
  final User user;

  const AuthTokens({required this.token, required this.user});

  @override
  List<Object> get props => [token, user];
}