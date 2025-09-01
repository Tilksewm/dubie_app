import 'package:dubie_app/services/api_service.dart';
import 'package:dubie_app/services/local_db_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider with ChangeNotifier {
  final RemoteApiService _apiService;
  final LocalDbService _dbService;
  User? currentUser;
  bool _isLoading = true;
  String? _fetchingError;

  bool get isLoading => _isLoading;

  String? get fetchingError => _fetchingError;

  UserProvider(SharedPreferences prefs) : _apiService = RemoteApiService(prefs), _dbService = LocalDbService(prefs);

  Future<void> getUserById(String userId) async {
    _isLoading = true;
    _fetchingError = null;
    //notifyListeners();
    try {
      currentUser = await _dbService.getUser(userId);
    } on ApiException catch (e) {
      _fetchingError = e.message;
    } catch (e) {
      _fetchingError = "unknown error occurred during fetching user info";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<User?> editTemporaryUser(String userId, {required String name, String? phone, String? email, String? username}) async {
    _isLoading = true;
    _fetchingError = null;
    //notifyListeners();
    try{
       currentUser = await _dbService.editTemporaryUser(userId, name: name, phone: phone, email: email,username: username);

    }on ApiException catch (e) {
      _fetchingError = e.message;
    } catch (e) {
      _fetchingError = "unknown error occurred during fetching user info";
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return currentUser;
  }
}