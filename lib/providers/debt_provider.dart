import 'package:dubie_app/models/debt_item.dart';
import 'package:dubie_app/services/local_db_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:dubie_app/services/api_service.dart';
import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/models/comment.dart';
import 'package:dubie_app/models/user.dart';
import 'package:uuid/uuid.dart'; // To get current user ID

class DebtThread{
  final Debt debt;
  final List<DebtItem> items;
  final List<Comment> comments;
  late double? outstandingAmount;
  late double? totalAmount;
  late double? totalPaid;


  DebtThread({
    required this.debt,
    required this.items,
    required this.comments,
  }) {
    if (items.isNotEmpty) {
      outstandingAmount = items.map((item) => item.amount - item.paidAmount).reduce((a, b) => (a + b));
      totalAmount = items.map((item) => item.amount).reduce((a, b) => (a + b));
      totalPaid = items.map((item) => item.paidAmount).reduce((a, b) => (a + b));
    } else {
      outstandingAmount = 0;
      totalAmount = 0;
      totalPaid = 0;
    }
  }
}
class CommentWithData {
  Comment comment;
  String commenterName;
  CommentWithData({required this.comment, required this.commenterName});
}
class DebtProvider with ChangeNotifier {
  //final RemoteApiService _apiService;
  final LocalDbService _dbService;
  final SharedPreferences _prefs; // Needed to get current user ID

  DebtThread? _currentDebt;
  List<DebtThread>? _debtsWithUser; // List of debts with a specific user
  List<CommentWithData>? _comments;

  bool _isLoadingDebt = true;
  bool _isLoadingDebtsWithUser = false;
  bool _isLoadingComments = false;
  bool _isActionInProgress = false; // For actions like adding item, paying, etc.

  String? _debtError;
  String? _debtsWithUserError;
  String? _commentsError;
  String? _actionError;

  final uuid = Uuid();

  DebtProvider(this._prefs) : _dbService = LocalDbService(_prefs);

  LocalDbService get dbService => _dbService;
  DebtThread? get currentDebt => _currentDebt;
  List<DebtThread>? get debtsWithUser => _debtsWithUser;
  List<CommentWithData>? get comments => _comments;

  bool get isLoadingDebt => _isLoadingDebt;
  bool get isLoadingDebtsWithUser => _isLoadingDebtsWithUser;
  bool get isLoadingComments => _isLoadingComments;
  bool get isActionInProgress => _isActionInProgress;

  String? get debtError => _debtError;
  String? get debtsWithUserError => _debtsWithUserError;
  String? get commentsError => _commentsError;
  String? get actionError => _actionError;

  String? get currentUserId => _prefs.getString('user_id');
  String generateId() => uuid.v4(); 

  // --- Debt List with a Specific User ---
  Future<void> fetchDebtsWithUser(String otherUserId) async {
    _isLoadingDebtsWithUser = true;
    _debtsWithUserError = null;
    String currentUserId = _prefs.getString('user_id')!;
    //notifyListeners();
    try {
      // Call the NEW backend endpoint
      List<Debt> debts = await _dbService.getDebtsWithUser(currentUserId, otherUserId);
      _debtsWithUser = await Future.wait(debts.map((debt) async {
        return DebtThread(
          debt: debt,
          items: await _dbService.getDebtItems(debt.id),
          comments: await _dbService.getComments(debt.id),
        );
      }));
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
      Debt? debt = await _dbService.getDebt(debtId);
      if (debt != null) {
        final items = await _dbService.getDebtItems(debt.id);
        final comments = await _dbService.getComments(debt.id);
        _currentDebt = DebtThread(
          debt: debt,
          items: items,
          comments: comments,
        );
      } else {
        _currentDebt = null;
        _debtError = 'Debt not found';
      }
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
      final comments = await _dbService.getComments(debtId);
      _comments = await Future.wait(comments.map( (comment) async{
        final commenter = await _dbService.getUser(comment.userId);
        return CommentWithData(comment: comment, commenterName: commenter!.name);
      }));
      _comments!.sort(
        (a, b) => DateTime.parse(a.comment.createdAt).compareTo(DateTime.parse(b.comment.createdAt)),
      ); // Sort comments by date
    } catch (e) {
      _commentsError = 'Failed to load comments: $e';
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  // --- Actions on Debt ---
  Future<void> addDebtItem(DebtItem debtItem) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      // The backend will update the debt status
      await _dbService.addDebtItem(debtItem);
      // Re-fetch debt details to get updated amounts and items
      await fetchDebtDetails(debtItem.debtId);
    } catch (e) {
      _actionError = 'Failed to add item: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> payDebtItem(DebtItem debtItem) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _dbService.updateDebtItem(debtItem);
      // After payment, refresh the debt details to get updated amounts and item status
      await fetchDebtDetails(debtItem.debtId);
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> updateDebtItem(DebtItem debtItem) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _dbService.updateDebtItem(debtItem);
      await fetchDebtDetails(debtItem.debtId);
    } catch (e) {
      _actionError = 'Failed to update the Debt Item: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
    //return debtItem;
  }

  Future<void> deleteDebt(DebtThread debtThread) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _dbService.deleteDebt(debtThread);
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> deleteDebtItem(DebtItem debtItem) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _dbService.deleteDebtItem(debtItem);
    } catch (e) {
      _actionError = 'Failed to record payment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }
  Future<void> updateDebt(Debt debt) async{
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _dbService.updateDebt(debt);
      await fetchDebtDetails(debt.id);
    } catch (e) {
      _actionError = 'Failed to update the Debt: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Future<void> updateDebtDescription(String debtId, String description) async {
  //   _isActionInProgress = true;
  //   _actionError = null;
  //   //notifyListeners();
  //   try {
  //     await _dbService.updateDebtDescription(debtId, description);
  //   } on ApiException catch (e) {
  //     _actionError = e.message;
  //     rethrow;
  //   } catch (e) {
  //     _actionError = 'Failed to record payment: $e';
  //     rethrow;
  //   } finally {
  //     _isActionInProgress = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> addComment(String debtId, String commentText) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      Comment comment = Comment(
        id: generateId(),
        commentText: commentText,
        createdAt: DateTime.now().toIso8601String(),
        userId: currentUserId!,
        syncStatus: SyncStatus.created,
        debtId: debtId
      );
      await _dbService.addComment(comment);
      User? currentUser = await _dbService.getUser(currentUserId!);
      if (_comments != null) {
        _comments!.add(CommentWithData(comment: comment, commenterName: currentUser!.name));
      } else {
        _comments = [CommentWithData(comment: comment, commenterName: currentUser!.name)];
      }
      _comments!.sort((a, b) => DateTime.parse(a.comment.createdAt).compareTo(DateTime.parse(b.comment.createdAt))); // Re-sort
    } catch (e) {
      _actionError = 'Failed to add comment: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> acceptDebt(Debt debt) async {
    _isActionInProgress = true;
    _actionError = null;
    //notifyListeners();
    try {
      await _dbService.acceptDebt(debt);
      await fetchDebtDetails(debt.id); // Refresh status
    } catch (e) {
      _actionError = 'Failed to accept debt: $e';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> rejectDebt(Debt debt) async {
    _isActionInProgress = true;
    _actionError = null;
    notifyListeners();
    try {
      await _dbService.rejectDebt(debt);
      await fetchDebtDetails(debt.id); // Refresh status
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
