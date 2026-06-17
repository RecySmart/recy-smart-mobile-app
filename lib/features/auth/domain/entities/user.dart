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
  final String id;
  final int currentBalance;
  final int lifetimeEarned;
  final int totalBottles;
  final double totalWeight;
  final double weight;
  final double co2Saved;
  final WalletLevel? level;

  const Wallet({
    required this.id,
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
  final String id;
  final String name;
  final int minPointsRequired;

  const WalletLevel({
    required this.id,
    required this.name,
    required this.minPointsRequired,
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