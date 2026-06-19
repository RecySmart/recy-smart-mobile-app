import '../../domain/entities/level.dart';

class LevelModel extends Level {
  const LevelModel({
    required super.id,
    required super.name,
    required super.minPointsRequired,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      minPointsRequired: (json['minPointsRequired'] as num?)?.toInt() ?? 0,
    );
  }
}