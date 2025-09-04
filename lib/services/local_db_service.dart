// lib/services/local_db_service.dart
import 'package:dubie_app/providers/debt_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../models/user.dart';
import '../models/debt_item.dart';
import '../models/comment.dart';
// ... other models

class LocalDbService {
  final SharedPreferences prefs;
  LocalDbService(this.prefs);
  // Hive Boxes
  Future<Box<Debt>> get debtBox async => Hive.openBox<Debt>('debts');
  Future<Box<User>> get userBox async => Hive.openBox<User>('users');
  Future<Box<DebtItem>> get debtItemBox async => Hive.openBox<DebtItem>('debt_items');
  Future<Box<Comment>> get commentBox async => Hive.openBox<Comment>('comments');

  // --- CRUD Operations for Debt Items ---
  Future<void> addDebtItem(DebtItem debtItem) async {
    final box = await debtItemBox;
    debtItem.syncStatus = SyncStatus.created;
    await box.put(debtItem.id, debtItem);
  }

  Future<List<DebtItem>> getDebtItems(String debtId) async {
    final box = await debtItemBox;
    return box.values.where((item) => item.debtId == debtId).toList();
  }

  Future<void> updateDebtItem(DebtItem updatedDebtItem) async {
    final box = await debtItemBox;
    updatedDebtItem.syncStatus = SyncStatus.updated;
    await box.put(updatedDebtItem.id, updatedDebtItem);
  }

  Future<void> deleteDebtItem(DebtItem debtItem) async{
    final box = await debtItemBox;
    debtItem.syncStatus = SyncStatus.deleted;
    await box.put(debtItem.id, debtItem);
  }

  // --- CRUD Operations for Comments ---
  Future<void> addComment(Comment comment) async {
    final box = await commentBox;
    comment.syncStatus = SyncStatus.created;
    await box.put(comment.id, comment);
  }

  Future<List<Comment>> getComments(String debtId) async {
    final box = await commentBox;
    return box.values.where((comment) => comment.debtId == debtId).toList();
  }

  Future<void> updateComment(Comment updatedComment) async {
    final box = await commentBox;
    updatedComment.syncStatus = SyncStatus.updated;
    await box.put(updatedComment.id, updatedComment);
  }
  Future<void> deleteComment(Comment comment) async {
    final box = await commentBox;
    comment.syncStatus = SyncStatus.deleted;
    await box.put(comment.id, comment);
  }

  // --- CRUD Operations for Debts ---
  Future<void> addDebt(Debt debt) async {
    final box = await debtBox;
    debt.syncStatus = SyncStatus.created;
    await box.put(debt.id, debt);
  }
  // TODO: we will add two parameter for
  Future<Debt?> getDebt(String debtId) async {
    final box = await debtBox;
    return box.get(debtId);
  }

  Future<void> updateDebt(Debt updatedDebt) async {
    final box = await debtBox;
    updatedDebt.syncStatus = SyncStatus.updated;
    await box.put(updatedDebt.id, updatedDebt);
  }

  Future<List<Debt>> getDebtsWithUser(String currentUserId, String otherUserId) async {
    final box = await debtBox;
    return box.values
        .where((debt) =>
            (debt.creditorId == currentUserId && debt.borrowerId == otherUserId) ||
            (debt.creditorId == otherUserId && debt.borrowerId == currentUserId))
        .toList();
  }
  Future<void> deleteDebt(DebtThread debtThread) async {
    final box = await debtBox;
    for (var debtItem in debtThread.items){
      deleteDebtItem(debtItem);
    }
    debtThread.debt.syncStatus = SyncStatus.deleted;
    await box.put(debtThread.debt.id, debtThread.debt);
  }

  Future<void> addUser(User user) async {
    final box = await userBox;
    user.syncStatus = SyncStatus.created;
    await box.put(user.id, user);
  }

  Future<User?> getUser(String userId) async {
    final box = await userBox;
    return box.get(userId);
  }

  Future<void> updateUser(User updatedUser) async {
    final box = await userBox;
    updatedUser.syncStatus = SyncStatus.updated;
    await box.put(updatedUser.id, updatedUser);
  }

  Future<void> deleteUser(User user) async {
    final box = await userBox;
    final dBox = await debtBox;
    final dItemBox = await debtItemBox;
    user.syncStatus = SyncStatus.deleted;
    await box.put(user.id, user);
    final debts = dBox.values.where((debt) => debt.creditorId == user.id).toList();
    for (var debt in debts) {
      debt.syncStatus = SyncStatus.deleted;
      await dBox.put(debt.id, debt);
      
      final debtItems = dItemBox.values.where((debtItem) => debtItem.debtId == debt.id).toList();
      for (var debtItem in debtItems) {
        deleteDebtItem(debtItem);
      }
    }
  }

  Future<void> acceptDebt(Debt debt) async {
    final box = await debtBox;
    debt.status = 'accepted';
    debt.syncStatus = SyncStatus.updated;
    await box.put(debt.id, debt);
  }

  Future<void> rejectDebt(Debt debt) async {
    final box = await debtBox;
    debt.status = 'rejected';
    debt.syncStatus = SyncStatus.updated;
    await box.put(debt.id, debt);
  }

  Future<Map<String, double>?> getHomeSummary() async {
    final box = await debtBox;
    String userId = prefs.getString('user_id') ?? '';
    double totalOwedToOthers = 0;
    double totalOwedByOthers = 0;
    List<Debt> debtsOwedToOthers = [];
    debtsOwedToOthers = box.values.where((debt) =>
        debt.creditorId == userId
    ).toList();
    List<Debt> debtsOwedByOthers = [];
    debtsOwedByOthers = box.values.where((debt) =>
        debt.borrowerId == userId
    ).toList();
    List<DebtItem> debtItemsOwedToOthers = [];
    for (var debt in debtsOwedToOthers) {
      debtItemsOwedToOthers.addAll(await getDebtItems(debt.id));
    }
    List<DebtItem> debtItemsOwedByOthers = [];
    for (var debt in debtsOwedByOthers) {
      debtItemsOwedByOthers.addAll(await getDebtItems(debt.id));
    }
    totalOwedToOthers = debtItemsOwedToOthers.fold(0, (sum, item) => sum + (item.amount - item.paidAmount));
    totalOwedByOthers = debtItemsOwedByOthers.fold(0, (sum, item) => sum + (item.amount - item.paidAmount));

    return {
      'lent': totalOwedToOthers,
      'borrow': totalOwedByOthers,
    };
  }

  Future<List<HomeUser>?> getHomeUsers({required String filter}) async {
    if (filter == 'creditors') {
      final debtBoxInstance = await debtBox;
      final userBoxInstance = await userBox;
      String userId = prefs.getString('user_id') ?? '';
      // Get all debts where the current user is the borrower
      List<Debt> debtsOwedByUser = debtBoxInstance.values.where((debt) =>
          debt.borrowerId == userId
      ).toList();
      // order debtOwedByUser by recent updatedAt date first
      debtsOwedByUser.sort((a,b) => DateTime.parse(b.updatedAt).compareTo(DateTime.parse(a.updatedAt)));
      // Get unique creditor IDs
      Set<String> creditorIds = debtsOwedByUser.map((debt) => debt.creditorId).toSet();
      List<HomeUser> creditors = [];
      for (var creditorId in creditorIds) {
        User? user = userBoxInstance.get(creditorId);
        if (user != null) {
          // Calculate total amount owed to this creditor
          final type = user.userType;
          double totalAmount = 0;
          List<String> recentItems = [];
          for (var debt in debtsOwedByUser.where((debt) => debt.creditorId == creditorId)) {
            List<DebtItem> items = await getDebtItems(debt.id);
            for (var item in items) {
              totalAmount += (item.amount - item.paidAmount);
              if (recentItems.length < 3) {
                recentItems.add(item.description);
              }
            }
          }
          creditors.add(HomeUser(
            userId: creditorId,
            name: user.name,
            totalAmount: totalAmount,
            type: type,
            recentItems: recentItems,
          ));
        }
      }
      return creditors;
    } else if (filter == 'borrowers') {
      final debtBoxInstance = await debtBox;
      final userBoxInstance = await userBox;
      String userId = prefs.getString('user_id') ?? '';
      // Get all debts where the current user is the borrower
      List<Debt> debtsOwedToUser = debtBoxInstance.values.where((debt) =>
          debt.creditorId == userId
      ).toList();
      // order debtOwedToUser by recent updatedAt date first
      debtsOwedToUser.sort((a,b) => DateTime.parse(b.updatedAt).compareTo(DateTime.parse(a.updatedAt)));
      // Get unique creditor IDs
      Set<String> borrowerIds = debtsOwedToUser.map((debt) => debt.borrowerId).toSet();
      List<HomeUser> borrowers = [];
      for (var borrowerId in borrowerIds) {
        User? user = userBoxInstance.get(borrowerId);
        if (user != null) {
          // Calculate total amount owed to this creditor
          final type = user.userType;
          double totalAmount = 0;
          List<String> recentItems = [];
          for (var debt in debtsOwedToUser.where((debt) => debt.borrowerId == borrowerId)) {
            List<DebtItem> items = await getDebtItems(debt.id);
            for (var item in items) {
              totalAmount += (item.amount - item.paidAmount);
              if (recentItems.length < 3) {
                recentItems.add(item.description);
              }
            }
          }
          borrowers.add(HomeUser(
            userId: borrowerId,
            name: user.name,
            totalAmount: totalAmount,
            type: type,
            recentItems: recentItems,
          ));
        }
      }
      return borrowers;
    }
    return null;
  }

  Future<User?> editTemporaryUser(String userId, {required String name, String? phone, String? email, String? username}) async {
    final box = await userBox;
    User? user = box.get(userId);

    if (user != null && user.userType != 'real') {
      user.name = name;
      if (phone != null) user.phone = phone;
      if (email != null) user.email = email;
      if (username != null) user.username = username;
      user.syncStatus = SyncStatus.updated;
      await box.put(user.id, user);
      return user;
    }
    return null;
  }

  Future<User> createPlaceholderUser({required String name, String? phone, String? email, String? username}) async {
    print('Creating placeholder user with name: $name, phone: $phone, email: $email, username: $username');
    final box = await userBox;
    String userId = Uuid().v4();
    User user = User(
      id: userId,
      email: email,
      name: name,
      username: username,
      phone: phone,
      userType: 'placeholder',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    user.syncStatus = SyncStatus.created;
    print('Creating placeholder user: $user');
    await box.put(user.id, user);
    print('Placeholder user created with ID: ${user.id}');
    return user;
  }
}