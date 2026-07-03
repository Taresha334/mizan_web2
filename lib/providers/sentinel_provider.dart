import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SentinelProvider extends ChangeNotifier {
  bool _isAlive = false;
  DateTime? _lastHeartbeat;
  String _lastSmsSnippet = "No Data";

  bool get isAlive => _isAlive;
  String get lastSmsSnippet => _lastSmsSnippet;

  String get statusMessage {
    if (!_isAlive) return "SENTINEL OFFLINE";
    if (_lastHeartbeat == null) return "INITIALIZING...";
    final diff = DateTime.now().difference(_lastHeartbeat!);
    if (diff.inMinutes > 5) return "SENTINEL STALLED";
    return "SENTINEL ACTIVE";
  }

  SentinelProvider() {
    // Start the heartbeat monitor
    Timer.periodic(const Duration(seconds: 10), (timer) => checkStatus());
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString('sentinel_heartbeat');
    _lastSmsSnippet =
        prefs.getString('last_telebirr_sms') ?? "Waiting for SMS...";

    if (lastSeenStr != null) {
      _lastHeartbeat = DateTime.parse(lastSeenStr);
      // If the heartbeat is less than 2 minutes old, it's alive
      _isAlive = DateTime.now().difference(_lastHeartbeat!).inMinutes < 2;
    } else {
      _isAlive = false;
    }
    notifyListeners();
  }
}
