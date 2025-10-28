import 'package:flutter/cupertino.dart';

class SyncProvider extends ChangeNotifier{
  bool _isSynced = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    if (value != _isLoading) {
      _isLoading = value;
      notifyListeners();
    }
  }
  bool get isSynced => _isSynced;
  set isSynced(bool value) {
    if (value != _isSynced) {
      _isSynced = value;
      notifyListeners();
    }
  }
}