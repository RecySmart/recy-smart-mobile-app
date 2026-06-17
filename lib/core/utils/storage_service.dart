import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified storage service that uses:
/// - SharedPreferences on Web (flutter_secure_storage not supported)
/// - FlutterSecureStorage on Mobile/Desktop
class StorageService {
  final FlutterSecureStorage? _secure;
  final SharedPreferences _prefs;

  StorageService({
    required FlutterSecureStorage? secure,
    required SharedPreferences prefs,
  })  : _secure = secure,
        _prefs = prefs;

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      await _prefs.setString(key, value);
    } else {
      await _secure!.write(key: key, value: value);
    }
  }

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      return _prefs.getString(key);
    }
    return _secure!.read(key: key);
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      await _prefs.remove(key);
    } else {
      await _secure!.delete(key: key);
    }
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      await _prefs.clear();
    } else {
      await _secure!.deleteAll();
    }
  }
}