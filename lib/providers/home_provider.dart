import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Needed for RemoteApiService
import 'package:dubie_app/services/api_service.dart';
import 'package:dubie_app/models/user.dart'; // For HomeUser model

class HomeProvider with ChangeNotifier {
  final RemoteApiService _apiService;

  Map<String, double>? _homeSummary;
  List<HomeUser>? _creditors; // Users current user owes to
  List<HomeUser>? _borrowers;// Users who owe current user
  Map<String, String>? _userType;


  bool _isLoadingSummary = false;
  bool _isLoadingCreditors = false;
  bool _isLoadingBorrowers = false;
  bool _isLoadingUserType = false;

  String? _summaryError;
  String? _creditorsError;
  String? _borrowersError;
  String? _userTypeError;


  HomeProvider(SharedPreferences prefs) : _apiService = RemoteApiService(prefs);

  Map<String, double>? get homeSummary => _homeSummary;
  List<HomeUser>? get creditors => _creditors;
  List<HomeUser>? get borrowers => _borrowers;
  Map<String, String>? get userType => _userType;

  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingCreditors => _isLoadingCreditors;
  bool get isLoadingBorrowers => _isLoadingBorrowers;
  bool get isLoadingUserType =>_isLoadingUserType;

  String? get summaryError => _summaryError;
  String? get creditorsError => _creditorsError;
  String? get borrowersError => _borrowersError;
  String? get userTypeError => _userTypeError;

  RemoteApiService get apiService => _apiService;
  Future<void> fetchHomeSummary() async {
    _isLoadingSummary = true;
    _summaryError = null;
    //notifyListeners();
    try {
      _homeSummary = await _apiService.getHomeSummary();
    } on ApiException catch (e) {
      _summaryError = e.message;
    } catch (e) {
      _summaryError = 'Failed to load summary: $e';
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  // Future<void> getUserType(String userId) async {
  //   _isLoadingUserType = true;
  //   _userTypeError = null;
  //   notifyListeners();
  //   try {
  //     _userType = await _apiService.getUserType(userId);
  //   } on ApiException catch (e) {
  //     _userTypeError = e.message;
  //   } catch (e) {
  //     _userTypeError = 'Failed to load creditors: $e';
  //   } finally {
  //     _isLoadingUserType = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchCreditors() async {
    _isLoadingCreditors = true;
    _creditorsError = null;
    // notifyListeners();
    try {
      _creditors = await _apiService.getHomeUsers(filter: 'creditors');
    } on ApiException catch (e) {
      _creditorsError = e.message;
    } catch (e) {
      _creditorsError = 'Failed to load creditors: $e';
    } finally {
      _isLoadingCreditors = false;
      notifyListeners();
    }
  }

  Future<void> fetchBorrowers() async {
    _isLoadingBorrowers = true;
    _borrowersError = null;
    //notifyListeners();
    try {
      _borrowers = await _apiService.getHomeUsers(filter: 'borrowers');
    } on ApiException catch (e) {
      _borrowersError = e.message;
    } catch (e) {
      _borrowersError = 'Failed to load borrowers: $e';
    } finally {
      _isLoadingBorrowers = false;
      notifyListeners();
    }
  }

  // Call all fetches when needed
  Future<void> fetchAllHomeData() async {
    await Future.wait([
      fetchHomeSummary(),
      fetchCreditors(),
      fetchBorrowers(),
    ]);
  }
}