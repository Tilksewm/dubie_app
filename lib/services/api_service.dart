// lib/services/api_service.dart
import 'dart:convert';
import 'package:dubie_app/services/local_db_service.dart';
import 'package:dubie_app/services/sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_constants.dart';
import '../main.dart';
import '../models/user.dart';

class RemoteApiService {
  final SharedPreferences prefs;
  final FlutterSecureStorage _secureStorage;
  final String baseUrl = AppConstants.baseUrl;
  final LocalDbService localDbService;
  final SyncService syncService;

  final http.Client _httpClient;

  RemoteApiService(this.prefs) :
        _secureStorage = const FlutterSecureStorage(),
        _httpClient = http.Client(),
        localDbService = LocalDbService(prefs),
        syncService = SyncService();

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
    await prefs.remove('lastSyncedAt');
    // await _secureStorage.delete(key: 'pin');
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
          'id': prefs.getString('user_id'),
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
      final oldUserId = prefs.getString('user_id');
      await _saveAuthData(
        jwtToken: data['token'],
        userId: userData['id'],
        userEmail: userData['email'],
        userName: userData['name'],
        userPhone: userData['phone'],
        userUsername: userData['username'],
      );
      // replace the old id by new one, and map every data to use the new user id
      if (oldUserId != userData['id']){
        final userBox = await localDbService.userBox;
        userBox.delete(oldUserId);
      
        final currentUser = User(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
        phone: userData['phone'],
        username: userData['username'],
        userType: userData['user_type'],
        createdAt: userData['created_at'],
        updatedAt: userData['updated_at'], 
      );
      userBox.put(userData['id'], currentUser);
            // Update all related debts and comments with the new user ID
      final debtBox = await localDbService.debtBox;
      final commentBox = await localDbService.commentBox;
      for (var debt in debtBox.values) {
        if (debt.creditorId == oldUserId) {
          debt.creditorId = userData['id'];
          await debt.save();
        }
        if (debt.borrowerId == oldUserId) {
          debt.borrowerId = userData['id'];
          await debt.save();
        }
      }
      for (var comment in commentBox.values) {
        if (comment.userId == oldUserId) {
          comment.userId = userData['id'];
          await comment.save();
        }
      }
      }
      syncService.startSyncing();

    }
    if (kDebugMode) {
      print("Saved token: ${prefs.getString('jwt_token')}");
      print("Saved user_id: ${prefs.getString('user_id')}");
    }

    return data;
  }

  Future<void> signout() async {
    print('Signing out...');
    final url = Uri.parse('$baseUrl/auth/signout');
    print('sign out returned from the api call');
    try {
      await _sendRequest(
            () => _httpClient.post(url, headers: _getHeaders()),
      );
      print('sign out returned from the api call');
    } catch (e) {
      print('Error during backend signout (expected if token expired/no blacklisting): $e');
    } finally {
      print('sync data start');
      syncService.stopSyncing();
      print('sync data end');
      print('clearing data');
      await _clearAuthData();
      print('auth data cleared');
      await localDbService.clearDb();
      print('local db cleared');
      //await syncService.syncData();
      homeProvider.fetchAllHomeData();
      print('home provider returned');
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