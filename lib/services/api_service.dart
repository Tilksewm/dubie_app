// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_constants.dart';
import '../models/user.dart';
import '../models/debt.dart';
import '../models/comment.dart';
//import '../models/debt_item.dart';
//import '../models/home_user.dart';

class RemoteApiService {
  final SharedPreferences prefs;
  final FlutterSecureStorage _secureStorage;
  final String baseUrl = AppConstants.baseUrl;

  final http.Client _httpClient;

  RemoteApiService(this.prefs) :
        _secureStorage = const FlutterSecureStorage(),
        _httpClient = http.Client();

  String? _getJwtToken() {
    return prefs.getString('jwt_token');
  }

  Future<void> _saveAuthData({
    required String jwtToken,
    required String userId,
    required String userEmail,
    required String userName,
    String? userPhone,
    String? userUsername,
  }) async {
    await prefs.setString('jwt_token', jwtToken);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_email', userEmail);
    await prefs.setString('user_name', userName);
    await prefs.setString('user_phone', userPhone ?? '');
    await prefs.setString('user_username', userUsername ?? '');
  }

  Future<void> _clearAuthData() async {
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_username');
    await _secureStorage.delete(key: 'pin');
    // Keep PIN data in secure storage, not cleared on logout
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = _getJwtToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- Core Request Method ---
  Future<http.Response> _sendRequest(
      Future<http.Response> Function() requestBuilder, {
        bool includeAuth = true,
      }) async {
    try {
      final response = await requestBuilder();
      return response;
    } catch (e) {
      print('Request error: $e');
      rethrow;
    }
  }

  // --- Auth Endpoints ---
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? username,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await _sendRequest(
          () => _httpClient.post(
        url,
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'username': username,
        }),
      ),
      includeAuth: false,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> signin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signin');
    final response = await _sendRequest(
          () => _httpClient.post(
        url,
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ),
      includeAuth: false,
    );
    final data = _handleResponse(response);
    if (data.containsKey('token') && data['token'] != null && data.containsKey('user') && data['user'] != null) {
      final userData = data['user'];
      await _saveAuthData(
        jwtToken: data['token'],
        userId: userData['id'],
        userEmail: userData['email'],
        userName: userData['name'],
        userPhone: userData['phone'],
        userUsername: userData['username'],
      );
    }
    print("Saved token: ${prefs.getString('jwt_token')}");
    print("Saved user_id: ${prefs.getString('user_id')}");

    return data;
  }

  Future<void> signout() async {
    final url = Uri.parse('$baseUrl/auth/signout');
    try {
      await _sendRequest(
            () => _httpClient.post(url, headers: _getHeaders()),
      );
    } catch (e) {
      print('Error during backend signout (expected if token expired/no blacklisting): $e');
    } finally {
      await _clearAuthData();
    }
  }

  // // --- Profile Endpoints ---
  // Future<User> getMyProfile() async {
  //   final userId = prefs.getString('user_id');
  //   if (userId == null) {
  //     throw ApiException('User ID not found in local storage. Please log in.');
  //   }
  //   final url = Uri.parse('$baseUrl/auth/profile');
  //   final response = await _sendRequest(
  //         () => _httpClient.get(url, headers: _getHeaders()),
  //   );
  //   final data = _handleResponse(response);
  //   return User.fromJson(data);
  // }

  // Future<User> updateMyProfile({
  //   String? name,
  //   String? username,
  //   String? phone,
  // }) async {
  //   final userId = prefs.getString('user_id');
  //   if (userId == null) {
  //     throw ApiException('User ID not found in local storage.');
  //   }
  //   final url = Uri.parse('$baseUrl/auth/profile/$userId');
  //   final Map<String, dynamic> body = {};
  //   if (name != null) body['name'] = name;
  //   if (username != null) body['username'] = username;
  //   if (phone != null) body['phone'] = phone;

  //   final response = await _sendRequest(
  //         () => _httpClient.put(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode(body),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return User.fromJson(data['user']);
  // }

  // // --- Home Screen Endpoints ---
  // Future<Map<String, double>> getHomeSummary() async {
  //   final url = Uri.parse('$baseUrl/users/home/summary');
  //   final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
  //   final data = _handleResponse(response);
  //   return {
  //     'borrow': (data['borrow'] as num).toDouble(),
  //     'lent': (data['lent'] as num).toDouble(),
  //   };
  // }

  // Future<List<HomeUser>> getHomeUsers({required String filter}) async {
  //   final url = Uri.parse('$baseUrl/users/home/users?filter=$filter');
  //   final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
  //   final List<dynamic> jsonList = _handleResponse(response);
  //   return jsonList.map((json) => HomeUser.fromJson(json)).toList();
  // }
  // Future<User> getUserInfo( String userId) async{
  //   final url = Uri.parse('$baseUrl/users/$userId');
  //   final response = await _sendRequest(
  //         () => _httpClient.get(
  //       url,
  //       headers: _getHeaders(),
  //     ),
  //   );
  //   final data = _handleResponse(response);

  //   return User.fromJson(data);
  // }
  // Future<User> createPlaceholderUser({
  //   required String name,
  //   String? phone,
  //   String? email,
  //   String? username,
  // }) async {
  //   final url = Uri.parse('$baseUrl/users/home/users');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({
  //         'name': name,
  //         'phone': phone,
  //         'email': email,
  //         'username': username,
  //       }),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return User.fromJson(data['user']);
  // }
  // Future<User> editTemporaryUser(String userId, {required String name, String? phone, String? email, String? username}) async {
  //   final url = Uri.parse('$baseUrl/users/home/$userId/edit');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({
  //         'name': name,
  //         'phone': phone,
  //         'email': email,
  //         'username': username,
  //       }),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   print(data);
  //   return User.fromJson(data);
  // }

  // // --- Debt Endpoints ---
  // Future<List<Debt>> getDebtThreadsWithUser(String otherUserId) async {
  //   final url = Uri.parse('$baseUrl/debts/threads-with-user/$otherUserId');
  //   final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
  //   final List<dynamic> jsonList = _handleResponse(response);
  //   return jsonList.map((json) => Debt.fromJson(json)).toList();
  // }

  // Future<String> createDebt({
  //   required Map<String, dynamic> borrowerInfo,
  //   String? overallDescription,
  //   required List<Map<String, dynamic>> items,
  // }) async {
  //   final url = Uri.parse('$baseUrl/debts');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({
  //         'borrowerInfo': borrowerInfo,
  //         'overall_description': overallDescription,
  //         'items': items,
  //       }),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return data['debt_id'];
  // }

  // Future<Debt> getDebtById(String debtId) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId');
  //   final response = await _sendRequest(
  //         () => _httpClient.get(url, headers: _getHeaders()),
  //   );
  //   final data = _handleResponse(response);
  //   return Debt.fromJson(data);
  // }
  // Future<void> deleteDebt(String debtId) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId');
  //   final response = await _sendRequest(
  //         () => _httpClient.delete(
  //       url,
  //       headers: _getHeaders(),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   if (kDebugMode) {
  //     print(data);
  //   }
  // }
  // Future<Debt> updateDebtDescription(String debtId, String description) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/update-description');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({'description': description}),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return Debt.fromJson(data['debt']);
  // }

  // Future<DebtItem> addDebtItem(String debtId, {
  //   required String description,
  //   required double price,
  //   double? paidAmount,
  // }) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/items');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({
  //         'description': description,
  //         'price': price,
  //         'paid_amount': paidAmount,
  //       }),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return DebtItem.fromJson(data['item']);
  // }

  // Future<void> updateDebtItem(String debtId, String itemId, {
  //   String? description,
  //   double? price,
  //   double? paidAmount,
  // }) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/items/$itemId/edit');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({
  //         'description': description,
  //         'price': price,
  //         'paid_amount': paidAmount,
  //       }),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   //return DebtItem.fromJson(data['item']);
  // }
  // Future<void> deleteDebtItem(String debtId, String debtItemId) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/items/$debtItemId');
  //   final response = await _sendRequest(
  //         () => _httpClient.delete(
  //       url,
  //       headers: _getHeaders(),

  //       //   'description': description,
  //       //   'price': price,
  //       //   'paid_amount': paidAmount,
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   if (kDebugMode) {
  //     print(data);
  //   }
  // }
  // Future<DebtItem> payDebtItem(String debtId, String itemId, double paidAmount) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/pay');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({
  //         'item_id': itemId,
  //         'paid_amount': paidAmount,
  //       }),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return DebtItem.fromJson(data['item']);
  // }

  // Future<Debt> acceptDebt(String debtId) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/accept');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(url, headers: _getHeaders()),
  //   );
  //   final data = _handleResponse(response);
  //   return Debt.fromJson(data['debt']);
  // }

  // Future<Debt> rejectDebt(String debtId) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/reject');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(url, headers: _getHeaders()),
  //   );
  //   final data = _handleResponse(response);
  //   return Debt.fromJson(data['debt']);
  // }

  // // --- Comments Endpoints ---
  // Future<List<Comment>> getCommentsForDebt(String debtId) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/comments');
  //   final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
  //   final List<dynamic> jsonList = _handleResponse(response);
  //   return jsonList.map((json) => Comment.fromJson(json)).toList();
  // }

  // Future<Comment> addCommentToDebt(String debtId, String commentText) async {
  //   final url = Uri.parse('$baseUrl/debts/$debtId/comments');
  //   final response = await _sendRequest(
  //         () => _httpClient.post(
  //       url,
  //       headers: _getHeaders(),
  //       body: json.encode({'comment': commentText}),
  //     ),
  //   );
  //   final data = _handleResponse(response);
  //   return Comment.fromJson(data);
  // }

  // --- Helper for handling API responses ---
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      Map<String, dynamic> errorData;
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'error': 'Unauthorized or Forbidden. Status: ${response.statusCode}'};
      }
      throw ApiException(
        'Session Invalid: ${errorData['error'] ?? 'Unauthorized or Forbidden'}. Please log in again.',
        statusCode: response.statusCode,
        details: errorData,
      );
    } else {
      Map<String, dynamic> errorData;
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'error': 'An unknown error occurred. Status: ${response.statusCode}'};
      }
      throw ApiException(
        errorData['error'] ?? 'Unknown API error',
        statusCode: response.statusCode,
        details: errorData,
      );
    }
  }

}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    return 'ApiException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
  }
}
// // lib/services/api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Still used for PIN
//
// import '../app_constants.dart';
// import '../models/user.dart';
// import '../models/debt.dart';
// import '../models/comment.dart';
//
// class RemoteApiService {
//   final SharedPreferences prefs;
//   final FlutterSecureStorage _secureStorage; // For PIN, not refresh token
//   final String baseUrl = AppConstants.baseUrl;
//
//   final http.Client _httpClient;
//
//   RemoteApiService(this.prefs) :
//         _secureStorage = const FlutterSecureStorage(),
//         _httpClient = http.Client();
//
//   String? _getJwtToken() {
//     return prefs.getString('jwt_token'); // Now storing JWT directly
//   }
//
//   Future<void> _saveAuthData({
//     required String jwtToken,
//     required String userId,
//     required String userEmail,
//     required String userName,
//     String? userPhone,
//     String? userUsername,
//   }) async {
//     await prefs.setString('jwt_token', jwtToken);
//     await prefs.setString('user_id', userId);
//     await prefs.setString('user_email', userEmail);
//     await prefs.setString('user_name', userName);
//     await prefs.setString('user_phone', userPhone ?? '');
//     await prefs.setString('user_username', userUsername ?? '');
//   }
//
//   Future<void> _clearAuthData() async {
//     await prefs.remove('jwt_token');
//     await prefs.remove('user_id');
//     await prefs.remove('user_email');
//     await prefs.remove('user_name');
//     await prefs.remove('user_phone');
//     await prefs.remove('user_username');
//     // Keep PIN data in secure storage, not cleared on logout
//   }
//
//   Map<String, String> _getHeaders({bool includeAuth = true}) {
//     final headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     };
//     if (includeAuth) {
//       final token = _getJwtToken();
//       if (token != null) {
//         headers['Authorization'] = 'Bearer $token';
//       }
//     }
//     return headers;
//   }
//
//   // --- Core Request Method (Simplified - no refresh logic) ---
//   Future<http.Response> _sendRequest(
//       Future<http.Response> Function() requestBuilder, {
//         bool includeAuth = true,
//       }) async {
//     try {
//       final response = await requestBuilder();
//       return response;
//     } catch (e) {
//       print('Request error: $e');
//       rethrow;
//     }
//   }
//
//   // --- Auth Endpoints ---
//   Future<Map<String, dynamic>> signup({
//     required String email,
//     required String password,
//     required String name,
//     String? phone,
//     String? username,
//   }) async {
//     final url = Uri.parse('$baseUrl/auth/signup');
//     final response = await _sendRequest(
//           () => _httpClient.post(
//         url,
//         headers: _getHeaders(includeAuth: false),
//         body: json.encode({
//           'email': email,
//           'password': password,
//           'name': name,
//           'phone': phone,
//           'username': username,
//         }),
//       ),
//       includeAuth: false,
//     );
//     return _handleResponse(response);
//   }
//
//   Future<Map<String, dynamic>> signin({
//     required String email,
//     required String password,
//   }) async {
//     final url = Uri.parse('$baseUrl/auth/signin');
//     final response = await _sendRequest(
//           () => _httpClient.post(
//         url,
//         headers: _getHeaders(includeAuth: false),
//         body: json.encode({
//           'email': email,
//           'password': password,
//         }),
//       ),
//       includeAuth: false,
//     );
//     final data = _handleResponse(response);
//     if (data.containsKey('token') && data['token'] != null && data.containsKey('user') && data['user'] != null) {
//       final userData = data['user'];
//       await _saveAuthData(
//         jwtToken: data['token'],
//         userId: userData['id'],
//         userEmail: userData['email'],
//         userName: userData['name'],
//         userPhone: userData['phone'],
//         userUsername: userData['username'],
//       );
//     }
//     return data;
//   }
//
//   Future<void> signout() async {
//     final url = Uri.parse('$baseUrl/auth/signout');
//     // For custom JWT, backend signout usually means nothing.
//     // Call it for consistency if backend has blacklisting, otherwise can remove.
//     try {
//       await _sendRequest(
//             () => _httpClient.post(url, headers: _getHeaders()),
//       );
//     } catch (e) {
//       print('Error during backend signout (expected if token expired/no blacklisting): $e');
//     } finally {
//       await _clearAuthData();
//     }
//   }
//
//   // --- Profile Endpoints ---
//   Future<User> getMyProfile() async {
//     final userId = prefs.getString('user_id');
//     if (userId == null) {
//       throw ApiException('User ID not found in local storage. Please log in.');
//     }
//     final url = Uri.parse('$baseUrl/auth/profile'); // New endpoint for fetching current user's profile
//     final response = await _sendRequest(
//           () => _httpClient.get(url, headers: _getHeaders()),
//     );
//     final data = _handleResponse(response);
//     // Backend's getProfile returns the raw user object (not nested under 'user')
//     return User.fromJson(data);
//   }
//
//   Future<User> updateMyProfile({
//     String? name,
//     String? username,
//     String? phone,
//   }) async {
//     final userId = prefs.getString('user_id');
//     if (userId == null) {
//       throw ApiException('User ID not found in local storage.');
//     }
//     final url = Uri.parse('$baseUrl/auth/profile/$userId'); // New endpoint for updating profile
//     final Map<String, dynamic> body = {};
//     if (name != null) body['name'] = name;
//     if (username != null) body['username'] = username;
//     if (phone != null) body['phone'] = phone;
//
//     final response = await _sendRequest(
//           () => _httpClient.put(
//         url,
//         headers: _getHeaders(),
//         body: json.encode(body),
//       ),
//     );
//     final data = _handleResponse(response);
//     // Backend's updateProfile returns { message: ..., user: {...} }
//     return User.fromJson(data['user']);
//   }
//
//
//   // ... (Other API methods remain largely the same, but ensure they use _sendRequest)
//   // Example for existing methods:
//   Future<Map<String, dynamic>> fetchHomeSummary() async {
//     final url = Uri.parse('$baseUrl/home/summary');
//     final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
//     return _handleResponse(response);
//   }
//
//   Future<List<Map<String, dynamic>>> fetchHomeUsers(String type) async {
//     final url = Uri.parse('$baseUrl/home/users/$type');
//     final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
//     return List<Map<String, dynamic>>.from(_handleResponse(response));
//   }
//
//   Future<Map<String, dynamic>> addDebt(Map<String, dynamic> debtData) async {
//     final url = Uri.parse('$baseUrl/debts');
//     final response = await _sendRequest(
//           () => _httpClient.post(url, headers: _getHeaders(), body: json.encode(debtData)),
//     );
//     return _handleResponse(response);
//   }
//
//   Future<List<Map<String, dynamic>>> fetchDebtDetails(String otherUserId) async {
//     final url = Uri.parse('$baseUrl/debts/user/$otherUserId');
//     final response = await _sendRequest(() => _httpClient.get(url, headers: _getHeaders()));
//     return List<Map<String, dynamic>>.from(_handleResponse(response));
//   }
//
//   Future<Map<String, dynamic>> addDebtItem(String debtId, Map<String, dynamic> itemData) async {
//     final url = Uri.parse('$baseUrl/debts/$debtId/items');
//     final response = await _sendRequest(
//           () => _httpClient.post(url, headers: _getHeaders(), body: json.encode(itemData)),
//     );
//     return _handleResponse(response);
//   }
//
//
//   Map<String, dynamic> _handleResponse(http.Response response) {
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       if (response.body.isNotEmpty) {
//         return json.decode(response.body);
//       }
//       return {};
//     } else if (response.statusCode == 401 || response.statusCode == 403) {
//       final errorData = json.decode(response.body);
//       String errorMessage = errorData['error'] ?? 'Unauthorized or Forbidden';
//       // If token is invalid/expired with a long-lived JWT, it means a serious issue or manual revocation.
//       // Force user to login
//       throw ApiException('Session Invalid: $errorMessage. Please log in again.', statusCode: response.statusCode);
//     } else if (response.statusCode == 404) {
//       throw ApiException('Not Found: ${response.body}', statusCode: response.statusCode);
//     } else if (response.statusCode == 500) {
//       throw ApiException('Server Error: ${response.body}', statusCode: response.statusCode);
//     } else {
//       throw ApiException('Request failed with status: ${response.statusCode}. Body: ${response.body}', statusCode: response.statusCode);
//     }
//   }
// }
//
// class ApiException implements Exception {
//   final String message;
//   final int? statusCode;
//
//   ApiException(this.message, {this.statusCode});
//
//   @override
//   String toString() {
//     return 'ApiException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
//   }
// }
// // import 'dart:convert';
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // import '../app_constants.dart';
// // import '../models/user.dart';
// // import '../models/debt.dart';
// // import '../models/comment.dart';
// //
// // class RemoteApiService {
// //   final SharedPreferences prefs;
// //   final FlutterSecureStorage _secureStorage;
// //   final String baseUrl = AppConstants.baseUrl;
// //
// //   RemoteApiService(this.prefs) : _secureStorage = const FlutterSecureStorage();
// //
// //   String? _getToken() {
// //     return prefs.getString('auth_token');
// //   }
// //   Future<String?> _getRefreshToken() async {
// //     return await _secureStorage.read(key: 'refresh_token');
// //   }
// //
// //   Map<String, String> _getHeaders({bool includeAuth = true}) {
// //     final headers = {
// //       'Content-Type': 'application/json',
// //       'Accept': 'application/json',
// //     };
// //     if (includeAuth) {
// //       final token = _getToken();
// //       if (token != null) {
// //         headers['Authorization'] = 'Bearer $token';
// //       }
// //     }
// //     return headers;
// //   }
// //
// //   // --- Auth Endpoints ---
// //   Future<Map<String, dynamic>> signup({
// //     required String email,
// //     required String password,
// //     required String name,
// //     String? phone,
// //     String? username,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/auth/signup');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(includeAuth: false),
// //       body: json.encode({
// //         'email': email,
// //         'password': password,
// //         'name': name,
// //         'phone': phone,
// //         'username': username,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     if (data.containsKey('session') && data['session'] != null) {
// //       prefs.setString('auth_token', data['session']['access_token']);
// //       await _secureStorage.write(key: 'refresh_token', value: data['session']['refresh_token']); // Save refresh token securely
// //       prefs.setString('user_id', data['user']['id']);
// //       prefs.setString('user_email', data['user']['email']);
// //       prefs.setString('user_name', data['user']['name']);
// //       prefs.setString('user_phone', data['user']['phone'] ?? '');
// //       prefs.setString('user_username', data['user']['username'] ?? '');
// //     }
// //     return data;
// //   }
// //
// //   Future<Map<String, dynamic>> signin({
// //     required String email,
// //     required String password,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/auth/signin');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(includeAuth: false),
// //       body: json.encode({
// //         'email': email,
// //         'password': password,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     if (data.containsKey('session') && data['session'] != null) {
// //       prefs.setString('auth_token', data['session']['access_token']);
// //       await _secureStorage.write(key: 'refresh_token', value: data['session']['refresh_token']); // Save refresh token securely
// //       prefs.setString('user_id', data['user']['id']);
// //       prefs.setString('user_email', data['user']['email']);
// //       prefs.setString('user_name', data['user']['name']);
// //       prefs.setString('user_phone', data['user']['phone'] ?? '');
// //       prefs.setString('user_username', data['user']['username'] ?? '');
// //       }
// //     return data;
// //   }
// //
// //   Future<void> signout() async {
// //     final url = Uri.parse('$baseUrl/auth/signout');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //     );
// //     _handleResponse(response);
// //     await prefs.remove('auth_token');
// //     await prefs.remove('user_id');
// //     await prefs.remove('user_email');
// //     await prefs.remove('user_name');
// //     await prefs.remove('user_phone');
// //     await prefs.remove('user_username');
// //     await _secureStorage.delete(key: 'refresh_token'); // Delete refresh token
// //   }
// //
// //   // --- User Endpoints ---
// //   Future<User> getMyProfile() async {
// //     final url = Uri.parse('$baseUrl/users/me');
// //     final response = await http.get(url, headers: _getHeaders());
// //     final data = _handleResponse(response);
// //     return User.fromJson(data);
// //   }
// //
// //   Future<User> updateMyProfile({
// //     String? name,
// //     String? phone,
// //     String? username,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/users/me');
// //     final response = await http.put(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({
// //         'name': name,
// //         'phone': phone,
// //         'username': username,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     return User.fromJson(data['user']); // Backend returns {message, user: {}}
// //   }
// //
// //   // --- Home Screen Endpoints ---
// //   Future<Map<String, double>> getHomeSummary() async {
// //     final url = Uri.parse('$baseUrl/users/home/summary');
// //     final response = await http.get(url, headers: _getHeaders());
// //     final data = _handleResponse(response);
// //     return {
// //       'borrow': (data['borrow'] as num).toDouble(),
// //       'lent': (data['lent'] as num).toDouble(),
// //     };
// //   }
// //
// //   Future<List<HomeUser>> getHomeUsers({required String filter}) async {
// //     final url = Uri.parse('$baseUrl/users/home/users?filter=$filter');
// //     final response = await http.get(url, headers: _getHeaders());
// //     final List<dynamic> jsonList = _handleResponse(response);
// //     return jsonList.map((json) => HomeUser.fromJson(json)).toList();
// //   }
// //   // Future<Map<String, String>> getUserType(String userId) async{
// //   //   final url = Uri.parse('$baseUrl/users/home/users/$userId/user-type');
// //   //   final response = await http.get(url, headers: _getHeaders());
// //   //   final data = _handleResponse(response);
// //   //   return data['user_type'];
// //   // }
// //
// //   Future<User> createPlaceholderUser({
// //     required String name,
// //     String? phone,
// //     String? email,
// //     String? username,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/users/home/users');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({
// //         'name': name,
// //         'phone': phone,
// //         'email': email,
// //         'username': username,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     return User.fromJson(data['user']); // Backend returns {message, user: {}}
// //   }
// //
// //   // --- Debt Endpoints ---
// //
// //   // Updated: Now calls the new backend endpoint for fetching debt threads with a specific user
// //   Future<List<Debt>> getDebtThreadsWithUser(String otherUserId) async {
// //     final url = Uri.parse('$baseUrl/debts/threads-with-user/$otherUserId');
// //     final response = await http.get(url, headers: _getHeaders());
// //     final List<dynamic> jsonList = _handleResponse(response);
// //     return jsonList.map((json) => Debt.fromJson(json)).toList();
// //   }
// //
// //   Future<String> createDebt({
// //     required Map<String, dynamic> borrowerInfo,
// //     String? overallDescription,
// //     required List<Map<String, dynamic>> items,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/debts');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({
// //         'borrowerInfo': borrowerInfo,
// //         'overall_description': overallDescription,
// //         'items': items,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     return data['debt_id'];
// //   }
// //
// //   Future<Debt> getDebtById(String debtId) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId');
// //     final response = await http.get(url, headers: _getHeaders());
// //     final data = _handleResponse(response);
// //     return Debt.fromJson(data);
// //   }
// //
// //   Future<Debt> updateDebtDescription(String debtId, String description) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/update-description');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({'description': description}),
// //     );
// //     final data = _handleResponse(response);
// //     return Debt.fromJson(data['debt']);
// //   }
// //
// //   Future<DebtItem> addDebtItem(String debtId, {
// //     required String description,
// //     required double price,
// //     double? paidAmount,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/items');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({
// //         'description': description,
// //         'price': price,
// //         'paid_amount': paidAmount,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     return DebtItem.fromJson(data['item']);
// //   }
// //
// //   Future<DebtItem> editDebtItem(String debtId, String itemId, {
// //     String? description,
// //     double? price,
// //     double? paidAmount,
// //   }) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/items/$itemId/edit');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({
// //         'description': description,
// //         'price': price,
// //         'paid_amount': paidAmount,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     return DebtItem.fromJson(data['item']);
// //   }
// //
// //   Future<DebtItem> payDebtItem(String debtId, String itemId, double paidAmount) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/pay');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({
// //         'item_id': itemId,
// //         'paid_amount': paidAmount,
// //       }),
// //     );
// //     final data = _handleResponse(response);
// //     return DebtItem.fromJson(data['item']);
// //   }
// //
// //   Future<Debt> acceptDebt(String debtId) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/accept');
// //     final response = await http.post(url, headers: _getHeaders());
// //     final data = _handleResponse(response);
// //     return Debt.fromJson(data['debt']);
// //   }
// //
// //   Future<Debt> rejectDebt(String debtId) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/reject');
// //     final response = await http.post(url, headers: _getHeaders());
// //     final data = _handleResponse(response);
// //     return Debt.fromJson(data['debt']);
// //   }
// //
// //   // --- Comments Endpoints ---
// //   Future<List<Comment>> getCommentsForDebt(String debtId) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/comments');
// //     final response = await http.get(url, headers: _getHeaders());
// //     final List<dynamic> jsonList = _handleResponse(response);
// //     return jsonList.map((json) => Comment.fromJson(json)).toList();
// //   }
// //
// //   Future<Comment> addCommentToDebt(String debtId, String commentText) async {
// //     final url = Uri.parse('$baseUrl/debts/$debtId/comments');
// //     final response = await http.post(
// //       url,
// //       headers: _getHeaders(),
// //       body: json.encode({'comment': commentText}),
// //     );
// //     final data = _handleResponse(response);
// //     return Comment.fromJson(data);
// //   }
// //
// //   // --- Helper for handling API responses ---
// //   dynamic _handleResponse(http.Response response) {
// //     if (response.statusCode >= 200 && response.statusCode < 300) {
// //       if (response.body.isEmpty) {
// //         return {}; // Return empty map for 204 No Content
// //       }
// //       return json.decode(response.body);
// //     } else {
// //       Map<String, dynamic> errorData;
// //       try {
// //         errorData = json.decode(response.body);
// //       } catch (e) {
// //         errorData = {'error': 'An unknown error occurred. Status: ${response.statusCode}'};
// //       }
// //       throw ApiException(
// //         errorData['error'] ?? 'Unknown API error',
// //         statusCode: response.statusCode,
// //         details: errorData,
// //       );
// //     }
// //   }
// // }
// //
// // class ApiException implements Exception {
// //   final String message;
// //   final int statusCode;
// //   final Map<String, dynamic>? details;
// //
// //   ApiException(this.message, {this.statusCode = 500, this.details});
// //
// //   @override
// //   String toString() {
// //     return 'ApiException: $message (Status: $statusCode)';
// //   }
// // }