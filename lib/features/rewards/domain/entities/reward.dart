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
  final String? availabilityStatus;
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
    this.availabilityStatus,
    this.expiresAt,
    this.category = 'General',
  });

  String get effectiveStatus => availabilityStatus ?? status;

  DateTime? get _expiration => DateTime.tryParse(expiresAt ?? '');

  bool get isExpired {
    final expiration = _expiration;
    return effectiveStatus == 'EXPIRED' ||
        (expiration != null && !expiration.isAfter(DateTime.now()));
  }

  bool get isAvailable =>
      effectiveStatus == 'ACTIVE' && remainingStock > 0 && !isExpired;

  bool get hasLowStock => isAvailable && remainingStock <= 5;

  bool get expiresSoon {
    final expiration = _expiration;
    if (!isAvailable || expiration == null) return false;
    final timeLeft = expiration.difference(DateTime.now());
    return timeLeft > Duration.zero && timeLeft <= const Duration(days: 7);
  }

  String get availabilityLabel {
    if (isExpired) return 'Vencido';
    if (effectiveStatus == 'DISCONTINUED') return 'Pausado';
    if (effectiveStatus == 'OUT_OF_STOCK' || remainingStock <= 0) {
      return 'Agotado';
    }
    return isAvailable ? 'Canjear Premio' : 'No disponible';
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        title,
        costInPoints,
        remainingStock,
        status,
        availabilityStatus,
        expiresAt,
      ];
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
