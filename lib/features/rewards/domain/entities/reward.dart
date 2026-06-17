import 'package:equatable/equatable.dart';

class Reward extends Equatable {
  final String id;
  final String companyId;
  final String companyName;
  final String? companyLogo;
  final String title;
  final String description;
  final int costInPoints;
  final int remainingStock;
  final String status;
  final String? expiresAt;
  final String category;

  const Reward({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
    required this.title,
    required this.description,
    required this.costInPoints,
    required this.remainingStock,
    required this.status,
    this.expiresAt,
    this.category = 'General',
  });

  bool get isAvailable => status == 'ACTIVE' && remainingStock > 0;

  @override
  List<Object?> get props =>
      [id, companyId, title, costInPoints, remainingStock, status];
}

class UserCoupon extends Equatable {
  final String id;
  final String rewardId;
  final String rewardTitle;
  final String companyName;
  final String qrCode;
  final String status;
  final DateTime expiresAt;
  final DateTime? redeemedAt;

  const UserCoupon({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.companyName,
    required this.qrCode,
    required this.status,
    required this.expiresAt,
    this.redeemedAt,
  });

  bool get isUnused => status == 'UNUSED';
  bool get isRedeemed => status == 'REDEEMED';
  bool get isExpired => status == 'EXPIRED';

  @override
  List<Object?> get props => [id, qrCode, status];
}