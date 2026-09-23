import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import '../utils/storage_service.dart';

typedef AchievementCallback   = void Function(Map<String, dynamic> data);
typedef CouponValidatedCallback = void Function(Map<String, dynamic> data);
typedef PointsUpdateCallback  = void Function(Map<String, dynamic> data);

class GlobalNotificationService {
  final StorageService _storage;
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  GlobalNotificationService(this._storage);

  bool get isConnected => _isConnected;

  Future<void> connect({
    required String userId,
    required AchievementCallback onAchievementUnlocked,
    required CouponValidatedCallback onCouponValidated,
    required PointsUpdateCallback onPointsUpdate,
  }) async {
    // Avoid reconnecting if already connected for the same user
    if (_isConnected && _currentUserId == userId) return;

    disconnect();
    _currentUserId = userId;
    
    final token = await _storage.read(key: AppConstants.accessTokenKey) ?? '';

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/api/socket.io')
          .setExtraHeaders({
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
            'Bypass-Tunnel-Reminder': 'true',
          })
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