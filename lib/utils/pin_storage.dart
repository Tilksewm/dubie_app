// lib/utils/pin_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _pinKey = 'app_pin';
  static const String _isPinEnabledKey = 'is_pin_enabled';

  // For storing temporary state or less sensitive info related to PIN attempts
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _lastPinAttemptTimeKey = 'last_pin_attempt_time';

  // Store the PIN securely
  static Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  // Retrieve the PIN securely
  static Future<String?> getPin() async {
    return await _secureStorage.read(key: _pinKey);
  }

  // Delete the PIN
  static Future<void> deletePin() async {
    await _secureStorage.delete(key: _pinKey);
  }

  // Toggle PIN enablement status (non-sensitive, can be in SharedPreferences)
  static Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPinEnabledKey, enabled);
  }

  // Check if PIN is enabled
  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPinEnabledKey) ?? false;
  }

  // --- PIN Attempt Tracking (Optional, for lockout) ---
  static Future<int> getPinAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pinAttemptsKey) ?? 0;
  }

  static Future<void> incrementPinAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = prefs.getInt(_pinAttemptsKey) ?? 0;
    await prefs.setInt(_pinAttemptsKey, attempts + 1);
  }

  static Future<void> resetPinAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pinAttemptsKey, 0);
    await prefs.remove(_lastPinAttemptTimeKey);
  }

  static Future<DateTime?> getLastPinAttemptTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastPinAttemptTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<void> setLastPinAttemptTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPinAttemptTimeKey, time.millisecondsSinceEpoch);
  }
}