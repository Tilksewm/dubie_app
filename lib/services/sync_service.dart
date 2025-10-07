import 'dart:async';
import 'dart:convert';
import 'package:dubie_app/app_constants.dart';
import 'package:dubie_app/main.dart';
import 'package:dubie_app/models/comment.dart';
import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/models/debt_item.dart';
import 'package:dubie_app/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your model classes with toJson and fromJson factories
// (Same as provided in the previous response)
// ...

class SyncService {
  SyncService();

  final String baseUrl = AppConstants.baseUrl;

  Future<Box<Debt>> get debtBox async => Hive.openBox<Debt>('debts');
  Future<Box<User>> get userBox async => Hive.openBox<User>('users');
  Future<Box<DebtItem>> get debtItemBox async => Hive.openBox<DebtItem>('debt_items');
  Future<Box<Comment>> get commentBox async => Hive.openBox<Comment>('comments');

  Timer? _syncTimer;
  void startSyncing() {

    // Prevent multiple timers from running
    if (_syncTimer?.isActive ?? false) return;

    print('Starting 3-minute sync timer...');
    // Execute the first sync immediately, then start the timer
    syncData();
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      syncData();
    });
  }

  // Stops the sync timer
  void stopSyncing() {
    print('Stopping sync timer...');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncData() async {
    print('sync start');
    syncProvider.isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    // Only proceed with sync if the user is signed in (token exists)
    if (token == null) {
      print('User is not signed in. Sync aborted.');
      syncProvider.isSynced = false;
      syncProvider.isLoading = false;
      return;
    }
    final userBox = await this.userBox;
    final debtBox = await this.debtBox;
    final debtItemBox = await this.debtItemBox;
    final commentBox = await this.commentBox;
    //final metadataBox = await this.metadataBox;

    print('initialized success');


    try {
      if(prefs.getString('lastSyncedAt') == null){
        prefs.setString('lastSyncedAt', '1970-01-01T00:00:00Z');
      }
      final lastSyncedAt = prefs.getString('lastSyncedAt');

      // 1. Collect unsynced data from local Hive boxes
      final unsyncedUsers = userBox.values.where((u) => u.syncStatus != SyncStatus.synced).toList();
      final unsyncedDebts = debtBox.values.where((d) => d.syncStatus != SyncStatus.synced).toList();
      final unsyncedDebtItems = debtItemBox.values.where((di) => di.syncStatus != SyncStatus.synced).toList();
      print('before comment');
      final unsyncedComments = commentBox.values.where((c) => c.syncStatus != SyncStatus.synced).toList();
      print('data collected');
      // 2. Prepare the payload
      final payload = {
        'lastSyncedAt': lastSyncedAt,
        'users': unsyncedUsers.map((u) => u.toJson()).toList(),
        'debts': unsyncedDebts.map((d) => d.toJson()).toList(),
        'debtItems': unsyncedDebtItems.map((di) => di.toJson()).toList(),
        'comments': unsyncedComments.map((c) => c.toJson()).toList(),
      };
      print('data organized');
      // 3. Set up the request with the JWT token
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      print('data sent');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('data received success');
        // 4. Process the server's response
        await _updateLocalDatabase(responseData);
        print('return from updating local db');

        // 5. Update the local lastSyncedAt timestamp
        await prefs.setString('lastSyncedAt', responseData['serverTime']);
        print('last synced at updated to ${responseData['serverTime']}');
        print('sync success!!!!');
        homeProvider.fetchAllHomeData();
        syncProvider.isSynced = true;
        syncProvider.isLoading = false;
      } else {
        // Handle API errors
        print('Sync failed with status code: ${response.statusCode}. Reason: ${response.body}');
        syncProvider.isSynced = false;
        syncProvider.isLoading = false;
      }
    } catch (e) {
      // Handle network or other exceptions
      print('An error occurred during sync: $e');
      syncProvider.isSynced = false;
      syncProvider.isLoading = false;
    }
  }

  Future<void> _updateLocalDatabase(Map<String, dynamic> data) async {
    print('updating local db start');
    final userBox = await this.userBox;
    final debtBox = await this.debtBox;
    final debtItemBox = await this.debtItemBox;
    final commentBox = await this.commentBox;
    print('updating local db box initialized');
    // Note: The order of updates is crucial to maintain referential integrity.
    final serverUpdates = data['updatedData'];
    final serverDeletions = data['deletedData'];
    final userIdMap = data['userIdMap'] as Map<String, dynamic>? ?? {};

    print('updating local db data received');

    // Handle the ID mapping for new users first
    if (userIdMap.isNotEmpty) {
      print('updating local db user reconciling');
      await _reconcileUserIds(userIdMap);
      print('updating local db user reconciling returned');
    }
    
    // 1. Handle remote User changes (create/update/delete)
    print('updating local db user handling');
    await _handleRemoteUpdates(serverUpdates['users'], userBox);
    await _handleRemoteDeletions(serverDeletions['users'], userBox);
    print('updating local db user handling returned');

    // 2. Handle remote Debt changes
    print('updating local db debt handling');
    await _handleRemoteUpdates(serverUpdates['debts'], debtBox);
    await _handleRemoteDeletions(serverDeletions['debts'], debtBox);
    print('updating local db debt handling returned');

    // 3. Handle remote DebtItem changes
    print('updating local db debtItem handling');
    await _handleRemoteUpdates(serverUpdates['debtItems'], debtItemBox);
    await _handleRemoteDeletions(serverDeletions['debtItems'], debtItemBox);
    print('updating local db debtItem handling returned');

    // 4. Handle remote Comment changes
    print('updating local db comment handling');
    await _handleRemoteUpdates(serverUpdates['comments'], commentBox);
    print('updating local db comment handling between update and delete');
    await _handleRemoteDeletions(serverDeletions['comments'], commentBox);
    print('updating local db comment handling returned');

    // 5. Update local items' sync status to 'synced'
    // _updateLocalSyncStatus(data['updatedLocalItems']);
  }

  Future<void> _handleRemoteUpdates(List? items, Box box) async {
    //TODO: we will update this into consise one
    if (items == null) return;
    if (box is Box<User>){
      for (var item in items) {
        final model = User.fromJson(item);
        model.syncStatus = SyncStatus.synced;
        await box.put(item['id'], model);
      }
    }else if (box is Box<Debt>){
      for (var item in items) {
        final model = Debt.fromJson(item);
        model.syncStatus = SyncStatus.synced;
        await box.put(item['id'], model);
      }
    }else if (box is Box<DebtItem>){
      for (var item in items) {
        final model = DebtItem.fromJson(item);
        model.syncStatus = SyncStatus.synced;
        await box.put(item['id'], model);
      }
    }else if (box is Box<Comment>){
      for (var item in items) {
        final model = Comment.fromJson(item);
        model.syncStatus = SyncStatus.synced;
        await box.put(item['id'], model);
      }
    }
  }

  Future<void> _handleRemoteDeletions(List? deletedIds, Box box) async {
    if (deletedIds == null) return;
    for (var id in deletedIds) {
      await box.delete(id);
    }
  }
  //
  // void _updateLocalSyncStatus(Map<String, dynamic> updatedLocalItems) {
  //   // This is the data returned from the server after it processed our local changes.
  //   final updatedUsers = updatedLocalItems['users'] as List<dynamic>? ?? [];
  //   final updatedDebts = updatedLocalItems['debts'] as List<dynamic>? ?? [];
  //   final updatedDebtItems = updatedLocalItems['debtItems'] as List<dynamic>? ?? [];
  //   final updatedComments = updatedLocalItems['comments'] as List<dynamic>? ?? [];
  //
  //   for (var id in updatedUsers) {
  //     final user = _userBox.get(id);
  //     if (user != null) {
  //       user.syncStatus = SyncStatus.synced;
  //       user.save();
  //     }
  //   }
  //   for (var id in updatedDebts) {
  //     final debt = _debtBox.get(id);
  //     if (debt != null) {
  //       debt.syncStatus = SyncStatus.synced;
  //       debt.save();
  //     }
  //   }
  //   for (var id in updatedDebtItems) {
  //     final debtItem = _debtItemBox.get(id);
  //     if (debtItem != null) {
  //       debtItem.syncStatus = SyncStatus.synced;
  //       debtItem.save();
  //     }
  //   }
  //   for (var id in updatedComments) {
  //     final comment = _commentBox.get(id);
  //     if (comment != null) {
  //       comment.syncStatus = SyncStatus.synced;
  //       comment.save();
  //     }
  //   }
  // }

  Future<void> _reconcileUserIds(Map<String, dynamic> userIdMap) async {
    final userBox = await this.userBox;
    final debtBox = await this.debtBox;
    final commentBox = await this.commentBox;
    for (var oldId in userIdMap.keys) {
      final newId = userIdMap[oldId];
      
      // Delete the old user entry from the local database
      await userBox.delete(oldId);
      
      // Update all related debts and comments with the new user ID
      for (var debt in debtBox.values) {
        if (debt.creditorId == oldId) {
          debt.creditorId = newId;
          await debt.save();
        }
        if (debt.borrowerId == oldId) {
          debt.borrowerId = newId;
          await debt.save();
        }
      }
      for (var comment in commentBox.values) {
        if (comment.userId == oldId) {
          comment.userId = newId;
          await comment.save();
        }
      }
    }
  }
}