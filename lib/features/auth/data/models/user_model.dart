import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      wallet: json['wallet'] != null
          ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };
}

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.currentBalance,
    required super.lifetimeEarned,
    required super.totalBottles,
    required super.totalWeight,
    required super.weight,
    required super.co2Saved,
    super.level,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    // Backend does NOT return 'id' in wallet — use a fallback
    final id = json['id'] as String? ?? 'wallet-${json['userId'] ?? 'local'}';
    final totalWeight = (json['totalWeight'] as num?)?.toDouble() ?? 0.0;
    final weight = (json['weight'] as num?)?.toDouble() ?? totalWeight / 1000;
    final co2Saved = (json['co2Saved'] as num?)?.toDouble() ?? weight * 1.5;

    return WalletModel(
      id: id,
      currentBalance: (json['currentBalance'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (json['lifetimeEarned'] as num?)?.toInt() ?? 0,
      totalBottles: (json['totalBottles'] as num?)?.toInt() ?? 0,
      totalWeight: totalWeight,
      weight: weight,
      co2Saved: co2Saved,
      level: json['level'] != null
          ? WalletLevelModel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WalletLevelModel extends WalletLevel {
  const WalletLevelModel({
    required super.id,
    required super.name,
    required super.minPointsRequired,
  });

  factory WalletLevelModel.fromJson(Map<String, dynamic> json) {
    return WalletLevelModel(
      // Backend only returns 'name' in the level object — id and minPoints are optional
      id: json['id'] as String? ?? 'level-local',
      name: json['name'] as String? ?? 'Eco Beginner',
      minPointsRequired: (json['minPointsRequired'] as num?)?.toInt() ?? 0,
    );
  }
}

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({required super.token, required super.user});

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}