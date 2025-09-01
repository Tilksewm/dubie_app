import 'dart:convert';
import 'package:dubie_app/app_constants.dart';
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
  final Box<User> _userBox;
  final Box<Debt> _debtBox;
  final Box<DebtItem> _debtItemBox;
  final Box<Comment> _commentBox;
  final Box<dynamic> _metadataBox;
  final String baseUrl = AppConstants.baseUrl;

  SyncService()
      : _userBox = Hive.box<User>('users'),
        _debtBox = Hive.box<Debt>('debts'),
        _debtItemBox = Hive.box<DebtItem>('debtItems'),
        _commentBox = Hive.box<Comment>('comments'),
        _metadataBox = Hive.box('metadata');

  Future<void> syncData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // Only proceed with sync if the user is signed in (token exists)
    if (token == null) {
      print('User is not signed in. Sync aborted.');
      return;
    }

    try {
      final lastSyncedAt = _metadataBox.get('lastSyncedAt', defaultValue: '1970-01-01T00:00:00Z');

      // 1. Collect unsynced data from local Hive boxes
      final unsyncedUsers = _userBox.values.where((u) => u.syncStatus != SyncStatus.synced).toList();
      final unsyncedDebts = _debtBox.values.where((d) => d.syncStatus != SyncStatus.synced).toList();
      final unsyncedDebtItems = _debtItemBox.values.where((di) => di.syncStatus != SyncStatus.synced).toList();
      final unsyncedComments = _commentBox.values.where((c) => c.syncStatus != SyncStatus.synced).toList();

      // 2. Prepare the payload
      final payload = {
        'lastSyncedAt': lastSyncedAt,
        'users': unsyncedUsers.map((u) => u.toJson()).toList(),
        'debts': unsyncedDebts.map((d) => d.toJson()).toList(),
        'debtItems': unsyncedDebtItems.map((di) => di.toJson()).toList(),
        'comments': unsyncedComments.map((c) => c.toJson()).toList(),
      };

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

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 4. Process the server's response
        await _updateLocalDatabase(responseData);

        // 5. Update the local lastSyncedAt timestamp
        _metadataBox.put('lastSyncedAt', responseData['serverTime']);
      } else {
        // Handle API errors
        print('Sync failed with status code: ${response.statusCode}. Reason: ${response.body}');
      }
    } catch (e) {
      // Handle network or other exceptions
      print('An error occurred during sync: $e');
    }
  }

  Future<void> _updateLocalDatabase(Map<String, dynamic> data) async {
    // Note: The order of updates is crucial to maintain referential integrity.
    final serverUpdates = data['updatedData'];
    final serverDeletions = data['deletedData'];
    final userIdMap = data['userIdMap'] as Map<String, dynamic>? ?? {};

    // Handle the ID mapping for new users first
    if (userIdMap.isNotEmpty) {
      await _reconcileUserIds(userIdMap);
    }
    
    // 1. Handle remote User changes (create/update/delete)
    await _handleRemoteUpdates(serverUpdates['users'], _userBox);
    await _handleRemoteDeletions(serverDeletions['users'], _userBox);

    // 2. Handle remote Debt changes
    await _handleRemoteUpdates(serverUpdates['debts'], _debtBox);
    await _handleRemoteDeletions(serverDeletions['debts'], _debtBox);

    // 3. Handle remote DebtItem changes
    await _handleRemoteUpdates(serverUpdates['debtItems'], _debtItemBox);
    await _handleRemoteDeletions(serverDeletions['debtItems'], _debtItemBox);

    // 4. Handle remote Comment changes
    await _handleRemoteUpdates(serverUpdates['comments'], _commentBox);
    await _handleRemoteDeletions(serverDeletions['comments'], _commentBox);

    // 5. Update local items' sync status to 'synced'
    _updateLocalSyncStatus(data['updatedLocalItems']);
  }

  Future<void> _handleRemoteUpdates(List? items, Box box) async {
    //TODO: we will update this into consise one
    if (items == null) return;
    if (box is Box<User>){
      for (var item in items) {
        final model = User.fromJson(item);
        // We assume the server-returned data has a 'synced' status
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

  void _updateLocalSyncStatus(Map<String, dynamic> updatedLocalItems) {
    // This is the data returned from the server after it processed our local changes.
    final updatedUsers = updatedLocalItems['users'] as List<dynamic>? ?? [];
    final updatedDebts = updatedLocalItems['debts'] as List<dynamic>? ?? [];
    final updatedDebtItems = updatedLocalItems['debtItems'] as List<dynamic>? ?? [];
    final updatedComments = updatedLocalItems['comments'] as List<dynamic>? ?? [];

    for (var id in updatedUsers) {
      final user = _userBox.get(id);
      if (user != null) {
        user.syncStatus = SyncStatus.synced;
        user.save();
      }
    }
    for (var id in updatedDebts) {
      final debt = _debtBox.get(id);
      if (debt != null) {
        debt.syncStatus = SyncStatus.synced;
        debt.save();
      }
    }
    for (var id in updatedDebtItems) {
      final debtItem = _debtItemBox.get(id);
      if (debtItem != null) {
        debtItem.syncStatus = SyncStatus.synced;
        debtItem.save();
      }
    }
    for (var id in updatedComments) {
      final comment = _commentBox.get(id);
      if (comment != null) {
        comment.syncStatus = SyncStatus.synced;
        comment.save();
      }
    }
  }

  Future<void> _reconcileUserIds(Map<String, dynamic> userIdMap) async {
    for (var oldId in userIdMap.keys) {
      final newId = userIdMap[oldId];
      
      // Delete the old user entry from the local database
      await _userBox.delete(oldId);
      
      // Update all related debts and comments with the new user ID
      for (var debt in _debtBox.values) {
        if (debt.creditorId == oldId) {
          debt.creditorId = newId;
          await debt.save();
        }
        if (debt.borrowerId == oldId) {
          debt.borrowerId = newId;
          await debt.save();
        }
      }
      for (var comment in _commentBox.values) {
        if (comment.commenterId == oldId) {
          comment.commenterId = newId;
          await comment.save();
        }
      }
    }
  }
}