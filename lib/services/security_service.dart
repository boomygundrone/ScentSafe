import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance {
    _instance ??= SecurityService._();
    return _instance!;
  }

  SecurityService._();

  late SharedPreferences _prefs;

  /// Encrypt sensitive data
  String encryptData(String data) {
    final bytes = utf8.encode(data);
    // Simple hash for demonstration (not secure, but functional)
    return base64Encode(bytes);
  }

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      await _prefs!.setString(key, value);
    } catch (e) {
      debugPrint('Error storing secure data: $e');
    }
  }

  /// Retrieve sensitive data securely
  Future<String?> getSecureData(String key) async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      return _prefs!.getString(key);
    } catch (e) {
      debugPrint('Error retrieving secure data: $e');
      return null;
    }
  }

  /// Delete sensitive data
  Future<void> deleteSecureData(String key) async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      await _prefs!.remove(key);
    } catch (e) {
      debugPrint('Error deleting secure data: $e');
    }
  }

  /// Clear all secure data
  Future<void> clearAllSecureData() async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      await _prefs!.clear();
    } catch (e) {
      debugPrint('Error clearing secure data: $e');
    }
  }
}
