import '../../domain/entities/recycling_session.dart';

class RecyclingSessionModel extends RecyclingSession {
  const RecyclingSessionModel({
    required super.sessionId,
    required super.binId,
    required super.locationName,
    super.bottlesDropped,
    super.pointsEarned,
    super.co2Saved,
    super.status,
  });

  factory RecyclingSessionModel.fromJson(Map<String, dynamic> json) {
    // The API returns the session data - adapt based on actual response shape
    final session = json['session'] as Map<String, dynamic>? ?? json;
    final bin = json['bin'] as Map<String, dynamic>? ?? {};

    return RecyclingSessionModel(
      sessionId:
          session['id'] as String? ?? session['sessionId'] as String? ?? '',
      binId: session['binId'] as String? ?? '',
      locationName: bin['location'] as String? ??
          bin['name'] as String? ??
          'RecySmart Bin',
      bottlesDropped: 0,
      pointsEarned: 0,
      co2Saved: 0.0,
      status: SessionStatus.active,
    );
  }
}
