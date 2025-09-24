import 'dart:async';

import 'package:flutter/cupertino.dart';

class LockedOutTimerProvider extends ChangeNotifier{
  Duration _remaining = Duration.zero;
  Timer? _timer;
  lockedOut(DateTime startedAt, Duration lockedOutDuration){
    _remaining = lockedOutDuration - DateTime.now().difference(startedAt);
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _remaining -= const Duration(seconds: 1);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
        _timer?.cancel();
      }
      notifyListeners();
    });
  }
  bool get isLockedOut => _remaining > Duration.zero;
  Duration get remaining => _remaining;
  void dispose() { _timer?.cancel(); super.dispose(); }
}