// lib/services/api_service.dart
import 'dart:convert';
import 'package:dubie_app/services/local_db_service.dart';
import 'package:dubie_app/services/sync_service.dart';
import 'package:flutter/foundation.dart';
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
  Future<void> deleteAccount() async {
    print('Deleting account...');
    final url = Uri.parse('$baseUrl/auth/delete-account');
    try {
      await _sendRequest(
            () => _httpClient.post(url, headers: _getHeaders()),
      );
      print('delete account returned from the api call');
    } catch (e) {
      print(
          'Error during backend delete account (expected if token expired/no blacklisting): $e');
    }
  }

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