import '../../domain/entities/smart_bin.dart';

class SmartBinModel extends SmartBin {
  const SmartBinModel({
    required super.id,
    required super.locationName,
    required super.latitude,
    required super.longitude,
    required super.status,
    required super.maxCapacity,
    required super.currentCapacity,
  });

  factory SmartBinModel.fromJson(Map<String, dynamic> json) {
    return SmartBinModel(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: _parseStatus(json['status'] as String?),
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 100,
      currentCapacity: (json['currentCapacity'] as num?)?.toInt() ?? 0,
    );
  }

  static BinStatus _parseStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'IN_USE':
        return BinStatus.inUse;
      case 'FULL':
        return BinStatus.full;
      case 'OFFLINE':
        return BinStatus.offline;
      default:
        return BinStatus.idle;
    }
  }
}