import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

typedef AchievementCallback   = void Function(Map<String, dynamic> data);
typedef CouponValidatedCallback = void Function(Map<String, dynamic> data);
typedef PointsUpdateCallback  = void Function(Map<String, dynamic> data);

/// Persistent app-wide socket connection.
/// Unlike SocketService (session-scoped, used during active recycling),
/// this connects once the user logs in and stays alive for the whole
/// app lifetime, listening to the user's personal room for:
///   - achievement_unlocked  (new badge earned)
///   - coupon_validated      (partner store scanned/validated a coupon)
///   - points_update         (any wallet balance change)
class GlobalNotificationService {
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  bool get isConnected => _isConnected;

  void connect({
    required String userId,
    required AchievementCallback onAchievementUnlocked,
    required CouponValidatedCallback onCouponValidated,
    required PointsUpdateCallback onPointsUpdate,
  }) {
    // Avoid reconnecting if already connected for the same user
    if (_isConnected && _currentUserId == userId) return;

    disconnect();
    _currentUserId = userId;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/api/socket.io')
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('🌐 Global socket connected — joining user room: $userId');
      _socket!.emit('joinUser', {'userId': userId});
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🌐 Global socket disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('❌ Global socket error: $err');
    });

    _socket!.on('achievement_unlocked', (data) {
      debugPrint('🏆 achievement_unlocked: $data');
      if (data is Map) onAchievementUnlocked(Map<String, dynamic>.from(data));
    });

    _socket!.on('coupon_validated', (data) {
      debugPrint('🎟️ coupon_validated: $data');
      if (data is Map) onCouponValidated(Map<String, dynamic>.from(data));
    });

    _socket!.on('points_update', (data) {
      debugPrint('💰 points_update: $data');
      if (data is Map) onPointsUpdate(Map<String, dynamic>.from(data));
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentUserId = null;
  }
}