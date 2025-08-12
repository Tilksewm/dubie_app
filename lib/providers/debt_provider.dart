import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dubie_app/services/api_service.dart';
import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/models/comment.dart';
import 'package:dubie_app/models/user.dart'; // To get current user ID

class DebtProvider with ChangeNotifier {
  final RemoteApiService _apiService;
  final SharedPreferences _prefs; // Needed to get current user ID

  Debt? _currentDebt;
  List<Debt>? _debtsWithUser; // List of debts with a specific user
  List<Comment>? _comments;

  bool _isLoadingDebt = true;
  bool _isLoadingDebtsWithUser = false;
  bool _isLoadingComments = false;
  bool _isActionInProgress = false; // For actions like adding item, paying, etc.

  String? _debtError;
  String? _debtsWithUserError;
  String? _commentsError;
  String? _actionError;

  DebtProvider(this._prefs) : _apiService = RemoteApiService(_prefs);

  RemoteApiService get apiService => _apiService;
  Debt? get currentDebt => _currentDebt;
  List<Debt>? get debtsWithUser => _debtsWithUser;
  List<Comment>? get comments => _comments;

  bool get isLoadingDebt => _isLoadingDebt;
  bool get isLoadingDebtsWithUser => _isLoadingDebtsWithUser;
  bool get isLoadingComments => _isLoadingComments;
  bool get isActionInProgress => _isActionInProgress;

  String? get debtError => _debtError;
  String? get debtsWithUserError => _debtsWithUserError;
  String? get commentsError => _commentsError;
  String? get actionError => _actionError;

  String? get currentUserId => _prefs.getString('user_id');

  // --- Debt List with a Specific User ---
  Future<void> fetchDebtsWithUser(String otherUserId) async {
    _isLoadingDebtsWithUser = true;
    _debtsWithUserError = null;
    //notifyListeners();
    try {
      // Call the NEW backend endpoint
      _debtsWithUser = await _apiService.getDebtThreadsWithUser(otherUserId);
    } on ApiException catch (e) {
      _debtsWithUserError = e.message;
    } catch (e) {
      _debtsWithUserError = 'Failed to load debts another_user_id = $otherUserId: $e';
    } finally {
      _isLoadingDebtsWithUser = false;
      notifyListeners();
    }
  }

  // --- Fetch a Specific Debt Thread (with items and comments) ---
  Future<void> fetchDebtDetails(String debtId) async {
    _isLoadingDebt = true;
    _debtError = null;
    //notifyListeners();
    try {
      _currentDebt = await _apiService.getDebtById(debtId);
      // Also fetch comments
      await fetchComments(debtId);
    } on ApiException catch (e) {
      _debtError = e.message;
    } catch (e) {
      _debtError = 'Failed to load debt details: $e';
    } finally {
      _isLoadingDebt = false;
      notifyListeners();
    }
  }

  Future<void> fetchComments(String debtId) async {
    _isLoadingComments = true;
    _commentsError = null;
    //notifyListeners();
    try {
      _comments = await _apiService.getCommentsForDebt(debtId);
      _comments!.sort((a, b) => a.date.compareTo(b.date)); // Sort comments by date
    } on ApiException catch (e) {
      _commentsError = e.message;
    } catch (e) {
      _commentsError = 'Failed to load comments: $e';
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  // --- Actions on Debt ---
  Future<void> addDebtItem(String debtId, {
    required String description,
    required double price,
    double? paidAmount,
  }) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      // The backend will update the debt status
      await _apiService.addDebtItem(
        debtId,
        description: description,
        price: price,
        paidAmount: paidAmount,
      );
      // Re-fetch debt details to get updated amounts and items
      await fetchDebtDetails(debtId);
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to add item: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> payDebtItem(String debtId, String itemId, double paidAmount) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _apiService.payDebtItem(debtId, itemId, paidAmount);
      // After payment, refresh the debt details to get updated amounts and item status
      await fetchDebtDetails(debtId);
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }
  Future<void> updateDebtItem(String debtId, String itemId, {
    String? description,
    double? price,
    double? paidAmount,
  }) async {
    DebtItem debtItem;
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _apiService.updateDebtItem(debtId, itemId, description: description, price:price, paidAmount:paidAmount);

    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to update the Debt Item: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
    //return debtItem;
  }
  Future<void> deleteDebt(String debtId) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _apiService.deleteDebt(debtId);

    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }
  Future<void> deleteDebtItem(String debtId, String debtItemId) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _apiService.deleteDebtItem(debtId, debtItemId);

    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }
  Future<void> updateDebtDescription(String debtId, String description) async{

    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _apiService.updateDebtDescription(debtId, description);

    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> addComment(String debtId, String commentText) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      final newComment = await _apiService.addCommentToDebt(debtId, commentText);
      if (_comments != null) {
        _comments!.add(newComment);
      } else {
        _comments = [newComment];
      }
      _comments!.sort((a, b) => a.date.compareTo(b.date)); // Re-sort
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to add comment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> acceptDebt(String debtId) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _apiService.acceptDebt(debtId);
      await fetchDebtDetails(debtId); // Refresh status
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to accept debt: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> rejectDebt(String debtId) async {
    _isActionInProgress = true;
    _actionError = null;
    notifyListeners();
    try {
      await _apiService.rejectDebt(debtId);
      await fetchDebtDetails(debtId); // Refresh status
    } on ApiException catch (e) {
      _actionError = e.message;
      rethrow;
    } catch (e) {
      _actionError = 'Failed to reject debt: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Helper method to clear current debt details when navigating away
  void clearCurrentDebt() {
    _currentDebt = null;
    _comments = null;
    _debtError = null;
    _commentsError = null;
    notifyListeners();
  }
}