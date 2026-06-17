import 'package:equatable/equatable.dart';

enum BinStatus { idle, inUse, full, offline }

class SmartBin extends Equatable {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final BinStatus status;
  final int maxCapacity;
  final int currentCapacity;

  const SmartBin({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.maxCapacity,
    required this.currentCapacity,
  });

  double get capacityPercentage =>
      maxCapacity > 0 ? (currentCapacity / maxCapacity) * 100 : 0;

  bool get isAvailable =>
      status == BinStatus.idle && capacityPercentage < 80;

  bool get isFull => capacityPercentage >= 80 || status == BinStatus.full;

  String get statusLabel {
    if (status == BinStatus.offline) return 'Offline';
    if (isFull) return 'Full';
    return 'Disponible (${capacityPercentage.toStringAsFixed(0)}%)';
  }

  @override
  List<Object> get props => [id, locationName, latitude, longitude, status];
}