import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import '../utils/storage_service.dart';

typedef SessionUpdateCallback = void Function(Map<String, dynamic> data);
typedef PointsUpdateCallback  = void Function(Map<String, dynamic> data);
typedef AchievementCallback   = void Function(Map<String, dynamic> data);

class SocketService {
  final StorageService _storage;
  io.Socket? _socket;
  bool _isConnected = false;
  int _connectionGeneration = 0;
  
  SocketService(this._storage);
  
  bool get isConnected => _isConnected;

  Future<void> connect({
    required String sessionId,
    required String userId,
    required SessionUpdateCallback onSessionUpdate,
    required PointsUpdateCallback onPointsUpdate,
    required AchievementCallback onAchievementUnlocked,
    VoidCallback? onReconnected,
  }) async {
    disconnect();
    final generation = _connectionGeneration;

    final token = await _storage.read(key: AppConstants.accessTokenKey) ?? '';
    if (generation != _connectionGeneration) return;

    final socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/api/socket.io')
          // The app-wide socket may already be connected to this same namespace.
          // Reusing it would skip onConnect and therefore skip joinSession.
          .enableForceNew()
          .setExtraHeaders({
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          })
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket = socket;
    var wasConnected = false;
    socket.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ Socket.io connected to ${AppConstants.socketUrl}');
      socket.emit('joinSession', {'sessionId': sessionId});
      socket.emit('joinUser', {'userId': userId});
      if (wasConnected) onReconnected?.call();
      wasConnected = true;
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
    _connectionGeneration++;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
