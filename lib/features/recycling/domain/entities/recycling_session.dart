import 'package:equatable/equatable.dart';

class RecyclingSession extends Equatable {
  final String sessionId;
  final String binId;
  final String locationName;
  final int bottlesDropped;
  final int pointsEarned;
  final double co2Saved;
  final SessionStatus status;

  const RecyclingSession({
    required this.sessionId,
    required this.binId,
    required this.locationName,
    this.bottlesDropped = 0,
    this.pointsEarned = 0,
    this.co2Saved = 0.0,
    this.status = SessionStatus.active,
  });

  RecyclingSession copyWith({
    int? bottlesDropped,
    int? pointsEarned,
    double? co2Saved,
    SessionStatus? status,
  }) =>
      RecyclingSession(
        sessionId: sessionId,
        binId: binId,
        locationName: locationName,
        bottlesDropped: bottlesDropped ?? this.bottlesDropped,
        pointsEarned: pointsEarned ?? this.pointsEarned,
        co2Saved: co2Saved ?? this.co2Saved,
        status: status ?? this.status,
      );

  @override
  List<Object> get props => [sessionId, binId, bottlesDropped, pointsEarned, status];
}

enum SessionStatus { active, completed, autoclosed, error }