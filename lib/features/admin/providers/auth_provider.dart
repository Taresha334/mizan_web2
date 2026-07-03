// filepath: lib/features/auth/providers/auth_provider.dart
// MIZAN CORE: RESILIENT AUTH PROVIDER (V2026.4)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? get currentUser => _supabase.auth.currentUser;

  // --- SYNCHRONOUS ROUTER STATE FLAGS ---
  bool _isCustomAuthenticated = false;
  bool get isCustomAuthenticated =>
      _isCustomAuthenticated || _supabase.auth.currentSession != null;

  String? _customRole;
  String? get customRole => _customRole;

  // Verification helper for Mizan Debugging
  bool get isReady => _supabase.rest.headers['apikey'] != null;

  AuthProvider() {
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _isCustomAuthenticated = true;
      _customRole = await getUserRole(session.user.id);
      notifyListeners();
    }

    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? currentSession = data.session;

      if (currentSession != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        if (_customRole == null) {
          _isCustomAuthenticated = true;
          _customRole = await getUserRole(currentSession.user.id);
          notifyListeners();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _clearCachedSession();
      }
    });
  }

  /// MIZAN PLC: Safe Role Verification
  /// Prevents PGRST116 crash if profile is missing during login
  Future<String?> getUserRole(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return data?['role'] as String?;
    } catch (e) {
      debugPrint("MIZAN AUTH ERROR: Role fetch failed -> $e");
      return null;
    }
  }

  /// Explicit Manual Login flow hook for Mizan Portals
  /// This completely blocks the return route until _customRole is locked into memory
  Future<bool> signInWithPassword(String email, String password) async {
    setLoading(true);
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session != null) {
        // Essential: Await the profile table request BEFORE turning on authenticated flags
        final role = await getUserRole(res.session!.user.id);
        _customRole = role;
        _isCustomAuthenticated = true;
        setLoading(false);
        notifyListeners(); // Router receives notification only when role is in memory
        return true;
      }
    } catch (e) {
      debugPrint("MIZAN ACTION FAILURE: Sign in authentication failed -> $e");
      _clearCachedSession();
    }
    setLoading(false);
    return false;
  }

  /// Safe Logout routine clearing local cached tokens cleanly
  Future<void> signOut() async {
    setLoading(true);
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _clearCachedSession();
    setLoading(false);
  }

  void _clearCachedSession() {
    _customRole = null;
    _isCustomAuthenticated = false;
    notifyListeners();
  }

  /// Emergency state reset for inactive buttons
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void notify() => notifyListeners();
}
