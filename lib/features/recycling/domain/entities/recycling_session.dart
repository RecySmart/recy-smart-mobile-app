import 'package:equatable/equatable.dart';

class RecyclingSession extends Equatable {
  final String sessionId;
  final String binId;
  final String locationName;
  final int bottlesDropped;
  final int pointsEarned;
  final double co2Saved;
  final SessionStatus status;
  final int? timeoutSeconds;
  final String? lastWsEvent; // 'bottle_accepted' | 'bottle_rejected' etc.

  const RecyclingSession({
    required this.sessionId,
    required this.binId,
    required this.locationName,
    this.bottlesDropped = 0,
    this.pointsEarned = 0,
    this.co2Saved = 0.0,
    this.status = SessionStatus.active,
    this.timeoutSeconds,
    this.lastWsEvent,
  });

  RecyclingSession copyWith({
    int? bottlesDropped,
    int? pointsEarned,
    double? co2Saved,
    SessionStatus? status,
    String? lastWsEvent,
  }) =>
      RecyclingSession(
        sessionId: sessionId,
        binId: binId,
        locationName: locationName,
        bottlesDropped: bottlesDropped ?? this.bottlesDropped,
        pointsEarned: pointsEarned ?? this.pointsEarned,
        co2Saved: co2Saved ?? this.co2Saved,
        status: status ?? this.status,
        timeoutSeconds: timeoutSeconds,
        lastWsEvent: lastWsEvent,
      );

  @override
  List<Object?> get props =>
      [sessionId, binId, bottlesDropped, pointsEarned, status, timeoutSeconds, lastWsEvent];
}

enum SessionStatus { active, completed, autoclosed, error }

class RecyclingSessionSnapshot extends Equatable {
  final String sessionId;
  final String smartBinId;
  final String? locationName;
  final String status;
  final int bottlesAccepted;
  final int pointsCalculated;
  final DateTime? expiresAt;
  final int? remainingSeconds;

  const RecyclingSessionSnapshot({
    required this.sessionId,
    required this.smartBinId,
    required this.status,
    required this.bottlesAccepted,
    required this.pointsCalculated,
    this.locationName,
    this.expiresAt,
    this.remainingSeconds,
  });

  bool get isActive => status == 'IN_PROGRESS';

  @override
  List<Object?> get props =>
      [
        sessionId,
        smartBinId,
        locationName,
        status,
        bottlesAccepted,
        pointsCalculated,
        expiresAt,
        remainingSeconds,
      ];
}
