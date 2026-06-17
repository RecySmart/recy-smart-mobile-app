import '../../domain/entities/reward.dart';

class RewardModel extends Reward {
  const RewardModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    super.companyLogo,
    required super.title,
    required super.description,
    required super.costInPoints,
    required super.remainingStock,
    required super.status,
    super.expiresAt,
    super.category,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>? ?? {};
    return RewardModel(
      id: json['id'] as String,
      companyId: json['companyId'] as String? ?? '',
      companyName: company['companyName'] as String? ?? 'Partner',
      companyLogo: company['logoUrl'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      costInPoints: (json['costInPoints'] as num).toInt(),
      remainingStock: (json['remainingStock'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      expiresAt: json['expiresAt'] as String?,
      category: _inferCategory(json['title'] as String),
    );
  }

  static String _inferCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('coffee') || t.contains('food') || t.contains('drink')) {
      return 'Food & Drink';
    }
    if (t.contains('bus') || t.contains('transport') || t.contains('ride')) {
      return 'Transport';
    }
    if (t.contains('eco') || t.contains('green') || t.contains('plant')) {
      return 'Eco';
    }
    return 'General';
  }
}

class UserCouponModel extends UserCoupon {
  const UserCouponModel({
    required super.id,
    required super.rewardId,
    required super.rewardTitle,
    required super.companyName,
    required super.qrCode,
    required super.status,
    required super.expiresAt,
    super.redeemedAt,
  });

  factory UserCouponModel.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] as Map<String, dynamic>? ?? {};
    final company = reward['company'] as Map<String, dynamic>? ?? {};
    return UserCouponModel(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      rewardTitle: reward['title'] as String? ?? 'Reward',
      companyName: company['companyName'] as String? ?? 'Partner',
      qrCode: json['qrCode'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.tryParse(json['redeemedAt'] as String)
          : null,
    );
  }
}