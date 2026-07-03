// filepath: lib/features/admin/widgets/sentinel_live_feed.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SentinelLiveFeed extends StatefulWidget {
  const SentinelLiveFeed({super.key});

  @override
  State<SentinelLiveFeed> createState() => _SentinelLiveFeedState();
}

class _SentinelLiveFeedState extends State<SentinelLiveFeed> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _lastEvent;
  bool _isVisible = false;
  StreamSubscription? _subscription;
  bool _isUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndListen();
  }

  /// Verifies safety checks BEFORE calling any Supabase stream channels
  void _checkPermissionsAndListen() {
    final user = _supabase.auth.currentUser;

    // Safety check: If no native user session is found, block instantly
    if (user == null) {
      setState(() => _isUnauthorized = true);
      return;
    }

    final String role = user.userMetadata?['role'] ?? '';
    final String email = user.email ?? '';

    // If they logged in via custom partner PIN paths, block the query from executing
    if (role == 'partner' || role == 'agent' || email.isEmpty) {
      debugPrint(
        "MIZAN GATEWAY: Aborted stream channel connection for restricted partner account.",
      );
      setState(() => _isUnauthorized = true);
      return;
    }

    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    try {
      _subscription = _supabase
          .from('telebirr_sentinel')
          .stream(primaryKey: ['transaction_id'])
          .order('received_at', ascending: false)
          .limit(1)
          .listen(
            (List<Map<String, dynamic>> data) {
              if (data.isNotEmpty && mounted) {
                final latest = data.first;

                final receivedAt = DateTime.parse(latest['received_at']);
                if (DateTime.now().difference(receivedAt).inSeconds < 30) {
                  setState(() {
                    _lastEvent = latest;
                    _isVisible = true;
                  });

                  Future.delayed(const Duration(seconds: 10), () {
                    if (mounted) setState(() => _isVisible = false);
                  });
                }
              }
            },
            onError: (error) {
              debugPrint("Handled stream runtime error safely: $error");
            },
            cancelOnError: true,
          );
    } catch (e) {
      debugPrint("Handled stream connection wrapper crash safely: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Drops out of the visual hierarchy entirely if unauthorized, preventing app crashes
    if (_isUnauthorized || !_isVisible || _lastEvent == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SENTINEL: PAY RECEIVED",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "ETB ${_lastEvent!['amount'] ?? '0.00'} | ${_lastEvent!['transaction_id']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white60, size: 18),
              onPressed: () => setState(() => _isVisible = false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
