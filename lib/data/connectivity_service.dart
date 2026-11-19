import 'dart:async';

import 'package:flutter/foundation.dart';

/// Toggleable connectivity for demos (mock offline without airplane mode).
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  bool get isOnline => _online;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _controller.add(_online);
    notifyListeners();
  }

  void toggle() => setOnline(!_online);

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
