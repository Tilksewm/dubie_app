// lib/providers/auth_provider.dart
import 'dart:async';

import 'package:dubie_app/services/local_db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dubie_app/services/api_service.dart';
import 'package:dubie_app/utils/pin_storage.dart';
import 'package:dubie_app/models/user.dart';
import 'package:uuid/uuid.dart';
// TODO: make signin and signup optional
// TODO: generate the user_id even if the user didn't registered
class AuthProvider with ChangeNotifier {
  final SharedPreferences prefs;
  late RemoteApiService _apiService;
  late LocalDbService _dbService;

  bool _isAuthenticated = false;
  User? _currentUser;

  bool _isPinEnabled = false;
  String? _pin;
  int _pinAttempts = 0;
  DateTime? _lastPinAttemptTime;
  final int _maxPinAttempts = 3;
  final Duration _pinLockoutDuration = const Duration(minutes: 1);

  bool _isLoading = true;

  Duration _remaining = Duration.zero;
  Timer? _timer;

  AuthProvider(this.prefs) {
    _apiService = RemoteApiService(prefs);
    _dbService = LocalDbService(prefs);
    _loadSessionAndPinStatus();
  }
  get apiService => _apiService;
  get dbService => _dbService;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Duration get remaining => _remaining;

  bool get isPinEnabled => _isPinEnabled;
  bool get isPinLockedOut {
    if (_pinAttempts >= _maxPinAttempts && _lastPinAttemptTime != null) {
      print(_pinAttempts);
      return DateTime.now().isBefore(_lastPinAttemptTime!.add(_pinLockoutDuration));
    }
    return false;
  }
  lockedOut(DateTime startedAt, Duration lockedOutDuration){
    _remaining = lockedOutDuration - DateTime.now().difference(startedAt);
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
    if (_timer?.isActive ?? false) return;
    _timer = Timer.periodic(Duration(seconds: 1), (_) async {
      _remaining -= const Duration(seconds: 1);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
        await PinStorage.resetPinAttempts();
        _timer?.cancel();
      }
      notifyListeners();
    });
  }

  Duration? get pinLockoutRemaining {
    if (isPinLockedOut && _lastPinAttemptTime != null) {
      final remaining = _lastPinAttemptTime!.add(_pinLockoutDuration).difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    }
    return null;
  }

  Future<void> _loadSessionAndPinStatus() async {
    if (kDebugMode) {
      print("Loaded token: ${prefs.getString('jwt_token')}");
      print("Loaded user_id: ${prefs.getString('user_id')}");
      print("pin status ${prefs.getString('pin')} ");
    }

    _isLoading = true;
    // Check for JWT token presence
    _isAuthenticated = prefs.getString('jwt_token') != null && prefs.getString('user_id') != null;

      try {
        _currentUser = await _dbService.getUser(prefs.getString('user_id')!);
      } on ApiException catch (e) {
        // If getUser fails due to token issues, force local logout
        print("Error fetching user profile on startup: $e. Forcing logout.");
        //await logout(notifyBackend: false); // Local logout
      } catch (e) {
        print("Unexpected error fetching user profile on startup: $e. Forcing logout.");
        //await logout(notifyBackend: false);
      }

    _isPinEnabled = await PinStorage.isPinEnabled();
    if (_isPinEnabled) {
      _pin = await PinStorage.getPin();
      _pinAttempts = await PinStorage.getPinAttempts();
      _lastPinAttemptTime = await PinStorage.getLastPinAttemptTime();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      await _apiService.signin(email: email, password: password);
      await _loadSessionAndPinStatus(); // Re-load session and user profile after successful login
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? username,
  }) async {
    try {
      await _apiService.signup(
        email: email,
        password: password,
        name: name,
        phone: phone,
        username: username,
      );
      // After signup, the user needs to verify email before they can log in.
      // Do not auto-login here. User needs to check email.
      // We might want to navigate to a "check your email" screen.
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout({bool notifyBackend = true}) async {
    print('logout start');
    try {
      await _apiService.signout(); // Call backend signout (if blacklisting implemented)
    } catch (e) {
      if (kDebugMode) {
        print('Error calling backend signout (expected for stateless JWT): $e');
      }
    } finally {
      _isAuthenticated = false;
      _currentUser = null;
      startWithNoAuth();
      // _isPinEnabled = false;
      // _pin = null;
      // await PinStorage.deletePin();
      // await PinStorage.setPinEnabled(false);
      // await PinStorage.resetPinAttempts();
      notifyListeners();
    }
  }

  // --- PIN Management (Remains the same as previous turn) ---
  Future<void> setPin(String newPin) async {
    if (newPin.length != 4) {
      throw Exception('PIN must be 4 digits.');
    }
    await PinStorage.setPin(newPin);
    _pin = newPin;
    _isPinEnabled = true;
    await PinStorage.setPinEnabled(true);
    await PinStorage.resetPinAttempts();
    notifyListeners();
  }

  Future<bool> verifyPin(String enteredPin) async {
    if (isPinLockedOut) {
      throw Exception('PIN entry is locked out. Please try again later.');
    }
    _pin ??= await PinStorage.getPin();

    if (enteredPin == _pin) {
      await PinStorage.resetPinAttempts();
      notifyListeners();
      return true;
    } else {
      await PinStorage.incrementPinAttempts();
      await PinStorage.setLastPinAttemptTime(DateTime.now());
      _pinAttempts = await PinStorage.getPinAttempts();
      _lastPinAttemptTime = await PinStorage.getLastPinAttemptTime();
      if (isPinLockedOut) {
        if (_pinAttempts >= _maxPinAttempts && _lastPinAttemptTime != null) {
          lockedOut(_lastPinAttemptTime!, _pinLockoutDuration);
        }
        throw Exception('Incorrect PIN. Maximum attempts reached.');
      } else {
        throw Exception('Incorrect PIN. ${_maxPinAttempts - _pinAttempts} attempts remaining.');
      }
    }
  }

  Future<void> disablePin() async {
    await PinStorage.deletePin();
    _pin = null;
    _isPinEnabled = false;
    await PinStorage.setPinEnabled(false);
    await PinStorage.resetPinAttempts();
    notifyListeners();
  }

  Future<void> changePin(String oldPin, String newPin) async {
    try {
      final bool verified = await verifyPin(oldPin);
      if (verified) {
        await setPin(newPin);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfileData() async {
    try {
      _currentUser = await _dbService.getUser(prefs.getString('user_id')!);
      notifyListeners();
    } on ApiException catch (e) {
      print("Error refreshing profile data from API: $e. Attempting logout.");
      await logout(notifyBackend: false);
    } catch (e) {
      print("Unexpected error refreshing profile data: $e. Attempting logout.");
      //await logout(notifyBackend: false);
    }
  }

  // Method to update user data locally after a successful profile update API call
  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> startWithNoAuth() async {
    print('start with no outh 1');
    if(prefs.getString('user_id') == null){
      print('start with no outh 2');
      final newUserId = Uuid().v4();
      prefs.setString('user_id', newUserId);
      final newUser = User(
        id: newUserId,
        email: null,
        name: 'Unknown',
        phone: null,
        username: null,
        userType: 'temporary',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String()
      );
      await _dbService.addUser(newUser);
      print('start with no outh 3 ${newUser.name}');
    }
    final newUserId = prefs.getString('user_id')!;
    _currentUser = await _dbService.getUser(newUserId);
    print('${_currentUser!.name}');
  }
}
