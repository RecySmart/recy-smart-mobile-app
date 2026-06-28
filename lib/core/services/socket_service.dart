import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

typedef SessionUpdateCallback = void Function(Map<String, dynamic> data);
typedef PointsUpdateCallback  = void Function(Map<String, dynamic> data);
typedef AchievementCallback   = void Function(Map<String, dynamic> data);

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect({
    required String sessionId,
    required String userId,
    required SessionUpdateCallback onSessionUpdate,
    required PointsUpdateCallback onPointsUpdate,
    required AchievementCallback onAchievementUnlocked,
  }) {
    disconnect();

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/api/socket.io')
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ Socket.io connected to ${AppConstants.socketUrl}');
      _socket!.emit('joinSession', {'sessionId': sessionId});
      _socket!.emit('joinUser',    {'userId': userId});
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🔌 Socket.io disconnected');
    });

    _socket!.onConnectError((err) => debugPrint('❌ Socket error: $err'));

    _socket!.on('session_update', (data) {
      if (data is Map) onSessionUpdate(Map<String, dynamic>.from(data));
    });

    _socket!.on('points_update', (data) {
      if (data is Map) onPointsUpdate(Map<String, dynamic>.from(data));
    });

    _socket!.on('achievement_unlocked', (data) {
      if (data is Map) onAchievementUnlocked(Map<String, dynamic>.from(data));
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}