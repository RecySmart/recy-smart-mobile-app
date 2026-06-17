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

  // Mock bins in Lima Metropolitana for when backend endpoint isn't ready yet
  static List<SmartBinModel> get mockBins => [
    const SmartBinModel(
      id: 'bin-001',
      locationName: 'Tambo - Carabayllo',
      latitude: -11.8491,
      longitude: -77.0200,
      status: BinStatus.idle,
      maxCapacity: 100,
      currentCapacity: 35,
    ),
    const SmartBinModel(
      id: 'bin-002',
      locationName: 'Mall Plaza Norte',
      latitude: -11.9833,
      longitude: -77.0733,
      status: BinStatus.idle,
      maxCapacity: 100,
      currentCapacity: 60,
    ),
    const SmartBinModel(
      id: 'bin-003',
      locationName: 'UNMSM Campus',
      latitude: -12.0566,
      longitude: -77.0843,
      status: BinStatus.inUse,
      maxCapacity: 100,
      currentCapacity: 20,
    ),
    const SmartBinModel(
      id: 'bin-004',
      locationName: 'Parque Kennedy - Miraflores',
      latitude: -12.1219,
      longitude: -77.0282,
      status: BinStatus.idle,
      maxCapacity: 100,
      currentCapacity: 80,
    ),
    const SmartBinModel(
      id: 'bin-005',
      locationName: 'CC Jockey Plaza',
      latitude: -12.0885,
      longitude: -76.9740,
      status: BinStatus.offline,
      maxCapacity: 100,
      currentCapacity: 0,
    ),
  ];
}