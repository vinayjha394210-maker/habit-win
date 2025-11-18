import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    if (_timer?.isActive ?? false) return;
    action();
    _timer = Timer(delay, () {});
  }

  void dispose() {
    _timer?.cancel();
  }
}
