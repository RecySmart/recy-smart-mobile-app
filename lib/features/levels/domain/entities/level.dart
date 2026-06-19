import 'package:equatable/equatable.dart';

class Level extends Equatable {
  final String id;
  final String name;
  final int minPointsRequired;

  const Level({
    required this.id,
    required this.name,
    required this.minPointsRequired,
  });

  // Icon and color per level tier
  String get emoji {
    switch (name) {
      case 'Eco Beginner':
        return '🌱';
      case 'Recycler Apprentice':
        return '♻️';
      case 'Green Warrior':
        return '🌿';
      case 'Eco Master':
        return '🌍';
      case 'Planet Guardian':
        return '🏆';
      default:
        return '⭐';
    }
  }

  @override
  List<Object> get props => [id, name, minPointsRequired];
}