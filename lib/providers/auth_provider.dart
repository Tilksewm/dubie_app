// lib/providers/auth_provider.dart
import 'package:dubie_app/services/local_db_service.dart';
import 'package:flutter/material.dart';
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
  final Duration _pinLockoutDuration = const Duration(minutes: 5);

  bool _isLoading = true;

  AuthProvider(this.prefs) {
    _apiService = RemoteApiService(prefs);
    _dbService = LocalDbService(prefs);
    _loadSessionAndPinStatus();
  }
  get apiService => _apiService;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  bool get isPinEnabled => _isPinEnabled;
  bool get isPinLockedOut {
    if (_pinAttempts >= _maxPinAttempts && _lastPinAttemptTime != null) {
      return DateTime.now().isBefore(_lastPinAttemptTime!.add(_pinLockoutDuration));
    }
    return false;
  }

  Duration? get pinLockoutRemaining {
    if (isPinLockedOut && _lastPinAttemptTime != null) {
      final remaining = _lastPinAttemptTime!.add(_pinLockoutDuration).difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    }
    return null;
  }

  Future<void> _loadSessionAndPinStatus() async {
    print("Loaded token: ${prefs.getString('jwt_token')}");
    print("Loaded user_id: ${prefs.getString('user_id')}");
    print("pin status ${prefs.getString('pin')} ");
    _isLoading = true;
    // Check for JWT token presence
    _isAuthenticated = prefs.getString('jwt_token') != null && prefs.getString('user_id') != null;

    if (_isAuthenticated) {
      try {
        // Fetch full user profile from the backend using the stored JWT
        _currentUser = await _dbService.getUser(prefs.getString('user_id')!);
      } on ApiException catch (e) {
        // If getUser fails due to token issues, force local logout
        print("Error fetching user profile on startup: $e. Forcing logout.");
        await logout(notifyBackend: false); // Local logout
      } catch (e) {
        print("Unexpected error fetching user profile on startup: $e. Forcing logout.");
        await logout(notifyBackend: false);
      }
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
      // You might want to navigate to a "check your email" screen.
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout({bool notifyBackend = true}) async {
    try {
      if (notifyBackend) {
        await _apiService.signout(); // Call backend signout (if blacklisting implemented)
      }
    } catch (e) {
      print('Error calling backend signout (expected for stateless JWT): $e');
    } finally {
      _isAuthenticated = false;
      _currentUser = null;
      _isPinEnabled = false;
      _pin = null;
      await PinStorage.deletePin();
      await PinStorage.setPinEnabled(false);
      await PinStorage.resetPinAttempts();
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

    if (_pin == null) {
      _pin = await PinStorage.getPin();
    }

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
        throw Exception('Incorrect PIN. Maximum attempts reached. Locked for ${_pinLockoutDuration.inMinutes} minutes.');
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
      await logout(notifyBackend: false);
    }
  }

  // Method to update user data locally after a successful profile update API call
  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> startWithNoAuth() async {
    if(prefs.getString('user_id') == null){
      final newUserId = Uuid().v4();
      prefs.setString('user_id', newUserId);
      await _dbService.addUser(User(
        id: newUserId,
        email: null,
        name: 'Unknown',
        phone: null,
        username: null,
        userType: 'temporary',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String()
      ));
    }
    final newUserId = prefs.getString('user_id')!;
    _currentUser = await _dbService.getUser(newUserId);
    notifyListeners();
  }
}
// // lib/providers/auth_provider.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:dubie_app/services/api_service.dart';
// import 'package:dubie_app/utils/pin_storage.dart'; // Import PinStorage
// import 'package:dubie_app/models/user.dart'; // Import the User model
//
// class AuthProvider with ChangeNotifier {
//   final SharedPreferences prefs;
//   late RemoteApiService _apiService;
//
//   bool _isAuthenticated = false;
//   User? _currentUser; // Store the full User object
//   // Removed individual fields as they can be accessed via _currentUser
//   // String? _userId;
//   // String? _userEmail;
//   // String? _userName;
//   // String? _userPhone;
//   // String? _userUsername;
//
//   bool _isPinEnabled = false;
//   String? _pin; // Stored PIN, fetched once
//   int _pinAttempts = 0;
//   DateTime? _lastPinAttemptTime;
//   final int _maxPinAttempts = 3;
//   final Duration _pinLockoutDuration = const Duration(minutes: 1); // Lockout for 5 minutes
//
//   bool _isLoading = true; // To indicate initial loading of auth state
//
//   AuthProvider(this.prefs) {
//     _apiService = RemoteApiService(prefs);
//     _loadSessionAndPinStatus();
//   }
//
//   bool get isAuthenticated => _isAuthenticated;
//   User? get currentUser => _currentUser;
//   bool get isLoading => _isLoading;
//
//   // PIN related getters
//   bool get isPinEnabled => _isPinEnabled;
//   bool get isPinLockedOut {
//     if (_pinAttempts >= _maxPinAttempts && _lastPinAttemptTime != null) {
//       return DateTime.now().isBefore(_lastPinAttemptTime!.add(_pinLockoutDuration));
//     }
//     return false;
//   }
//
//   Duration? get pinLockoutRemaining {
//     if (isPinLockedOut && _lastPinAttemptTime != null) {
//       final remaining = _lastPinAttemptTime!.add(_pinLockoutDuration).difference(DateTime.now());
//       return remaining.isNegative ? Duration.zero : remaining;
//     }
//     return null;
//   }
//
//
//   Future<void> _loadSessionAndPinStatus() async {
//     _isLoading = true;
//     // Removed direct access to prefs for individual user fields, now use getMyProfile
//     _isAuthenticated = prefs.getString('auth_token') != null && prefs.getString('user_id') != null;
//
//     if (_isAuthenticated) {
//       try {
//         _currentUser = await _apiService.getMyProfile(); // Fetch full user profile
//       } catch (e) {
//         // If profile fetching fails, perhaps token is invalid, log out
//         print("Error fetching user profile on startup: $e");
//         await logout();
//       }
//     }
//
//     // Load PIN status
//     _isPinEnabled = await PinStorage.isPinEnabled();
//     if (_isPinEnabled) {
//       _pin = await PinStorage.getPin(); // Fetch PIN once on app start
//       _pinAttempts = await PinStorage.getPinAttempts();
//       _lastPinAttemptTime = await PinStorage.getLastPinAttemptTime();
//     }
//
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   Future<void> login(String email, String password) async {
//     try {
//       await _apiService.signin(email: email, password: password);
//       await _loadSessionAndPinStatus(); // Re-load session and user profile after successful login
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<void> signup({
//     required String email,
//     required String password,
//     required String name,
//     String? phone,
//     String? username,
//   }) async {
//     try {
//       // Calls the API service signup
//       final response = await _apiService.signup(
//         email: email,
//         password: password,
//         name: name,
//         phone: phone,
//         username: username,
//       );
//       // If signup is successful, attempt to sign in the user
//       await login(email, password); // This will call signin and then _loadSessionAndPinStatus
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//
//   Future<void> logout() async {
//     try {
//       await _apiService.signout();
//       _isAuthenticated = false;
//       _currentUser = null;
//       _isPinEnabled = false; // Reset PIN state on logout
//       _pin = null;
//       await PinStorage.deletePin(); // Ensure PIN is removed on logout
//       await PinStorage.setPinEnabled(false);
//       await PinStorage.resetPinAttempts();
//       notifyListeners();
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   // --- PIN Management ---
//   Future<void> setPin(String newPin) async {
//     if (newPin.length != 4) {
//       throw Exception('PIN must be 4 digits.');
//     }
//     await PinStorage.setPin(newPin);
//     _pin = newPin;
//     _isPinEnabled = true;
//     await PinStorage.setPinEnabled(true);
//     await PinStorage.resetPinAttempts();
//     notifyListeners();
//   }
//
//   Future<bool> verifyPin(String enteredPin) async {
//     if (isPinLockedOut) {
//       throw Exception('PIN entry is locked out. Please try again later.');
//     }
//
//     if (_pin == null) {
//       _pin = await PinStorage.getPin(); // Try to fetch if not already loaded
//     }
//
//     if (enteredPin == _pin) {
//       await PinStorage.resetPinAttempts();
//       notifyListeners();
//       return true;
//     } else {
//       await PinStorage.incrementPinAttempts();
//       await PinStorage.setLastPinAttemptTime(DateTime.now());
//       _pinAttempts = await PinStorage.getPinAttempts(); // Update local state
//       _lastPinAttemptTime = await PinStorage.getLastPinAttemptTime();
//       if (isPinLockedOut) {
//         throw Exception('Incorrect PIN. Maximum attempts reached. Locked for ${_pinLockoutDuration.inMinutes} minutes.');
//       } else {
//         throw Exception('Incorrect PIN. ${_maxPinAttempts - _pinAttempts} attempts remaining.');
//       }
//     }
//   }
//
//   Future<void> disablePin() async {
//     await PinStorage.deletePin();
//     _pin = null;
//     _isPinEnabled = false;
//     await PinStorage.setPinEnabled(false);
//     await PinStorage.resetPinAttempts();
//     notifyListeners();
//   }
//
//   Future<void> changePin(String oldPin, String newPin) async {
//     try {
//       final bool verified = await verifyPin(oldPin);
//       if (verified) {
//         await setPin(newPin); // This will reset attempts and set new PIN
//       }
//     } catch (e) {
//       rethrow; // Re-throw verification error
//     }
//   }
//
//   // Call this to force a re-load of user data if profile changes, etc.
//   Future<void> refreshProfileData() async {
//     // Re-fetch profile from API to ensure it's up-to-date
//     try {
//       _currentUser = await _apiService.getMyProfile();
//       notifyListeners();
//     } catch (e) {
//       print("Error refreshing profile data: $e");
//       // Optionally handle by logging out if it's a critical error
//     }
//   }
//
//   // Method to update user data locally after a successful profile update API call
//   void updateCurrentUser(User updatedUser) {
//     _currentUser = updatedUser;
//     notifyListeners();
//   }
// }
// // // lib/providers/auth_provider.dart
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:dubie_app/services/api_service.dart';
// // import 'package:dubie_app/utils/pin_storage.dart';
// //
// // import '../models/user.dart'; // Import PinStorage
// //
// // class AuthProvider with ChangeNotifier {
// //   final SharedPreferences prefs;
// //   late RemoteApiService _apiService;
// //   User? _currentUser;
// //
// //   bool _isAuthenticated = false;
// //   String? _userId;
// //   String? _userEmail;
// //   String? _userName;
// //   String? _userPhone;
// //   String? _userUsername;
// //
// //   bool _isPinEnabled = false;
// //   String? _pin; // Stored PIN, fetched once
// //   int _pinAttempts = 0;
// //   DateTime? _lastPinAttemptTime;
// //   final int _maxPinAttempts = 3;
// //   final Duration _pinLockoutDuration = const Duration(minutes: 5); // Lockout for 5 minutes
// //
// //   bool _isLoading = true; // To indicate initial loading of auth state
// //
// //   AuthProvider(this.prefs) {
// //     _apiService = RemoteApiService(prefs);
// //     _loadSessionAndPinStatus();
// //   }
// //
// //   bool get isAuthenticated => _isAuthenticated;
// //   String? get userId => _userId;
// //   String? get userEmail => _userEmail;
// //   String? get userName => _userName;
// //   String? get userPhone => _userPhone;
// //   String? get userUsername => _userUsername;
// //   bool get isLoading => _isLoading;
// //
// //   // PIN related getters
// //   bool get isPinEnabled => _isPinEnabled;
// //   bool get isPinLockedOut {
// //     if (_pinAttempts >= _maxPinAttempts && _lastPinAttemptTime != null) {
// //       return DateTime.now().isBefore(_lastPinAttemptTime!.add(_pinLockoutDuration));
// //     }
// //     return false;
// //   }
// //
// //   Duration? get pinLockoutRemaining {
// //     if (isPinLockedOut && _lastPinAttemptTime != null) {
// //       final remaining = _lastPinAttemptTime!.add(_pinLockoutDuration).difference(DateTime.now());
// //       return remaining.isNegative ? Duration.zero : remaining;
// //     }
// //     return null;
// //   }
// //
// //
// //   Future<void> _loadSessionAndPinStatus() async {
// //     _isLoading = true;
// //     notifyListeners();
// //     _isAuthenticated = prefs.getString('auth_token') != null && prefs.getString('user_id') != null;
// //     _userId = prefs.getString('user_id');
// //     _userEmail = prefs.getString('user_email');
// //     _userName = prefs.getString('user_name');
// //     _userPhone = prefs.getString('user_phone');
// //     _userUsername = prefs.getString('user_username');
// //
// //     // Load PIN status
// //     _isPinEnabled = await PinStorage.isPinEnabled();
// //     if (_isPinEnabled) {
// //       _pin = await PinStorage.getPin(); // Fetch PIN once on app start
// //       _pinAttempts = await PinStorage.getPinAttempts();
// //       _lastPinAttemptTime = await PinStorage.getLastPinAttemptTime();
// //     }
// //
// //     _isLoading = false;
// //     notifyListeners();
// //   }
// //
// //     Future<void> signup({
// //     required String email,
// //     required String password,
// //     required String name,
// //     String? phone,
// //     String? username,
// //   }) async {
// //     try {
// //       final response = await _apiService.signup(
// //         email: email,
// //         password: password,
// //         name: name,
// //         phone: phone,
// //         username: username,
// //       );
// //       // For signup, you might not automatically log them in or receive a session directly
// //       // If your backend auto-logs in, then handle session storage like login
// //       // For now, assume a separate login after signup is needed unless backend implies otherwise
// //       // If backend returns session, then:
// //       // if (response.containsKey('session') && response['session'] != null) {
// //       //   prefs.setString('auth_token', response['session']['access_token']);
// //       //   prefs.setString('user_id', response['user']['id']);
// //       //   _currentUser = User.fromJson(response['user']);
// //       //   _isAuthenticated = true;
// //       // }
// //       // notifyListeners();
// //       await login(email, password);
// //     } catch (e) {
// //       rethrow;
// //     }
// //   }
// //   Future<void> login(String email, String password) async {
// //     try {
// //       await _apiService.signin(email: email, password: password);
// //       await _loadSessionAndPinStatus(); // Re-load session after successful login
// //     } catch (e) {
// //       rethrow;
// //     }
// //   }
// //
// //   Future<void> logout() async {
// //     try {
// //       await _apiService.signout();
// //       _isAuthenticated = false;
// //       _userId = null;
// //       _userEmail = null;
// //       _userName = null;
// //       _userPhone = null;
// //       _userUsername = null;
// //       _isPinEnabled = false; // Reset PIN state on logout
// //       _pin = null;
// //       await PinStorage.deletePin(); // Ensure PIN is removed on logout
// //       await PinStorage.setPinEnabled(false);
// //       await PinStorage.resetPinAttempts();
// //       notifyListeners();
// //     } catch (e) {
// //       rethrow;
// //     }
// //   }
// //
// //   // --- PIN Management ---
// //   Future<void> setPin(String newPin) async {
// //     if (newPin.length != 4) {
// //       throw Exception('PIN must be 4 digits.');
// //     }
// //     await PinStorage.setPin(newPin);
// //     _pin = newPin;
// //     _isPinEnabled = true;
// //     await PinStorage.setPinEnabled(true);
// //     await PinStorage.resetPinAttempts();
// //     notifyListeners();
// //   }
// //
// //   Future<bool> verifyPin(String enteredPin) async {
// //     if (isPinLockedOut) {
// //       throw Exception('PIN entry is locked out. Please try again later.');
// //     }
// //
// //     if (_pin == null) {
// //       _pin = await PinStorage.getPin(); // Try to fetch if not already loaded
// //     }
// //
// //     if (enteredPin == _pin) {
// //       await PinStorage.resetPinAttempts();
// //       notifyListeners();
// //       return true;
// //     } else {
// //       await PinStorage.incrementPinAttempts();
// //       await PinStorage.setLastPinAttemptTime(DateTime.now());
// //       _pinAttempts = await PinStorage.getPinAttempts(); // Update local state
// //       _lastPinAttemptTime = await PinStorage.getLastPinAttemptTime();
// //       if (isPinLockedOut) {
// //         throw Exception('Incorrect PIN. Maximum attempts reached. Locked for ${_pinLockoutDuration.inMinutes} minutes.');
// //       } else {
// //         throw Exception('Incorrect PIN. ${_maxPinAttempts - _pinAttempts} attempts remaining.');
// //       }
// //     }
// //   }
// //
// //   Future<void> disablePin() async {
// //     await PinStorage.deletePin();
// //     _pin = null;
// //     _isPinEnabled = false;
// //     await PinStorage.setPinEnabled(false);
// //     await PinStorage.resetPinAttempts();
// //     notifyListeners();
// //   }
// //
// //   Future<void> changePin(String oldPin, String newPin) async {
// //     try {
// //       final bool verified = await verifyPin(oldPin);
// //       if (verified) {
// //         await setPin(newPin); // This will reset attempts and set new PIN
// //       }
// //     } catch (e) {
// //       rethrow; // Re-throw verification error
// //     }
// //   }
// //
// //   // Call this to force a re-load of user data if profile changes, etc.
// //   Future<void> refreshProfileData() async {
// //     _userId = prefs.getString('user_id');
// //     _userEmail = prefs.getString('user_email');
// //     _userName = prefs.getString('user_name');
// //     _userPhone = prefs.getString('user_phone');
// //     _userUsername = prefs.getString('user_username');
// //     notifyListeners();
// //   }
// // }
// // // import 'package:flutter/material.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import '../models/user.dart'; // Ensure this path is correct
// // // import '../services/api_service.dart';
// // //
// // // class AuthProvider with ChangeNotifier {
// // //   User? _currentUser;
// // //   bool _isAuthenticated = false;
// // //   final SharedPreferences _prefs;
// // //   late final RemoteApiService _apiService;
// // //
// // //   AuthProvider(this._prefs) {
// // //     _apiService = RemoteApiService(_prefs);
// // //     _loadUserFromPrefs();
// // //   }
// // //
// // //   User? get currentUser => _currentUser;
// // //   bool get isAuthenticated => _isAuthenticated;
// // //
// // //   Future<void> _loadUserFromPrefs() async {
// // //     final userId = _prefs.getString('user_id');
// // //     final token = _prefs.getString('auth_token');
// // //
// // //     if (userId != null && token != null) {
// // //       try {
// // //         // Attempt to fetch current user's profile to validate token
// // //         _currentUser = await _apiService.getMyProfile();
// // //         _isAuthenticated = true;
// // //       } catch (e) {
// // //         // Token might be expired or invalid
// // //         print('Failed to load user from prefs or token invalid: $e');
// // //         await logout(); // Clear invalid session
// // //       }
// // //     } else {
// // //       _isAuthenticated = false;
// // //     }
// // //     notifyListeners();
// // //   }
// // //
// // //   Future<void> login(String email, String password) async {
// // //     try {
// // //       final response = await _apiService.signin(email: email, password: password);
// // //       _currentUser = User.fromJson(response['user']);
// // //       _isAuthenticated = true;
// // //       notifyListeners();
// // //     } catch (e) {
// // //       rethrow; // Re-throw the API exception
// // //     }
// // //   }
// // //
// // //   Future<void> signup({
// // //     required String email,
// // //     required String password,
// // //     required String name,
// // //     String? phone,
// // //     String? username,
// // //   }) async {
// // //     try {
// // //       final response = await _apiService.signup(
// // //         email: email,
// // //         password: password,
// // //         name: name,
// // //         phone: phone,
// // //         username: username,
// // //       );
// // //       // For signup, you might not automatically log them in or receive a session directly
// // //       // If your backend auto-logs in, then handle session storage like login
// // //       // For now, assume a separate login after signup is needed unless backend implies otherwise
// // //       // If backend returns session, then:
// // //       if (response.containsKey('session') && response['session'] != null) {
// // //         _prefs.setString('auth_token', response['session']['access_token']);
// // //         _prefs.setString('user_id', response['user']['id']);
// // //         _currentUser = User.fromJson(response['user']);
// // //         _isAuthenticated = true;
// // //       }
// // //       notifyListeners();
// // //     } catch (e) {
// // //       rethrow;
// // //     }
// // //   }
// // //
// // //   Future<void> logout() async {
// // //     try {
// // //       await _apiService.signout();
// // //     } catch (e) {
// // //       print('Error during logout API call (might be offline/token expired): $e');
// // //       // Still proceed with clearing local data
// // //     } finally {
// // //       _currentUser = null;
// // //       _isAuthenticated = false;
// // //       await _prefs.remove('auth_token');
// // //       await _prefs.remove('user_id');
// // //       notifyListeners();
// // //     }
// // //   }
// // //
// // //   // Method to update user profile locally after successful API call
// // //   void updateUserProfile(User updatedUser) {
// // //     _currentUser = updatedUser;
// // //     notifyListeners();
// // //   }
// // // }