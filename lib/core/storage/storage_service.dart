import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для безопасного хранения данных
/// На веб использует SharedPreferences, на мобильных - FlutterSecureStorage
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();

  final FlutterSecureStorage? _secureStorage = kIsWeb ? null : const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    if (kIsWeb && _prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> write(String key, String value) async {
    try {
      if (kIsWeb) {
        await _ensurePrefs();
        await _prefs?.setString(key, value);
      } else {
        await _secureStorage?.write(key: key, value: value);
      }
    } catch (e) {
      print('❌ Error writing to storage: $e');
      // Fallback для веб
      if (kIsWeb) {
        await _ensurePrefs();
        await _prefs?.setString(key, value);
      } else {
        rethrow;
      }
    }
  }

  Future<String?> read(String key) async {
    try {
      if (kIsWeb) {
        await _ensurePrefs();
        return _prefs?.getString(key);
      } else {
        return await _secureStorage?.read(key: key);
      }
    } catch (e) {
      print('❌ Error reading from storage: $e');
      if (kIsWeb) {
        await _ensurePrefs();
        return _prefs?.getString(key);
      }
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      if (kIsWeb) {
        await _ensurePrefs();
        await _prefs?.remove(key);
      } else {
        await _secureStorage?.delete(key: key);
      }
    } catch (e) {
      print('❌ Error deleting from storage: $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      if (kIsWeb) {
        await _ensurePrefs();
        await _prefs?.clear();
      } else {
        await _secureStorage?.deleteAll();
      }
    } catch (e) {
      print('❌ Error clearing storage: $e');
    }
  }
}

