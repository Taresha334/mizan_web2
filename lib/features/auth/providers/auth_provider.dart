// filepath: lib/features/auth/providers/auth_provider.dart
// MIZAN PLC: AUTHENTICATION PROVIDER (V9.6.4 - PRODUCTION READY)
// ARCHITECT: Mizan PLC Chief Systems Architect

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  bool _isCustomAuthenticated = false;
  String? _customRole;
  String? _customName;
  String? _customId;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isCustomAuthenticated => _isCustomAuthenticated;
  bool get isAuthenticated => (_user != null) || _isCustomAuthenticated;

  String? get customRole => _customRole;
  String? get customName => _customName;
  String? get customId => _customId;

  AuthProvider() {
    _init();
  }

  void _init() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      // We must fetch the profile immediately on app load to populate roles
      _fetchProfile(currentUser.id);
    }

    // Listen for auth changes to handle token refreshes or logouts
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _user = session?.user;

      if (_user == null) {
        _clearState();
      } else {
        // Only fetch if we aren't already authenticated to avoid redundant calls
        if (!_isCustomAuthenticated) {
          _fetchProfile(_user!.id);
        }
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        _isCustomAuthenticated = true;
        _customRole = (profile['role'] ?? 'user').toString().toLowerCase();
        _customName = profile['full_name'] ?? 'User';
        _customId = userId;
      } else {
        _clearState();
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
      _clearState();
    }
    notifyListeners();
  }

  /// BRIDGE METHOD: Added to maintain compatibility with updated UI
  /// This prevents the "method not found" error during the transition.
  Future<void> synchronizeProfileMetadata() async {
    if (_user != null) {
      await _fetchProfile(_user!.id);
    }
  }

  void _clearState() {
    _isCustomAuthenticated = false;
    _customRole = null;
    _customName = null;
    _customId = null;
  }

  Future<User?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      await _fetchProfile(_user!.id);
      return _user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signInFarmerWithPin(
    String phone,
    String pin,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final bridgeEmail = '$cleanPhone@mizan.plc';
      final securePassword = 'Mizan${pin.trim()}';

      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: bridgeEmail,
        password: securePassword,
      );

      if (authRes.user != null) {
        _user = authRes.user;
        await _fetchProfile(_user!.id);
        return {
          'login_status': 'SUCCESS',
          'user_role': _customRole,
          'full_name': _customName,
        };
      }
      return {'login_status': 'FAILED'};
    } catch (e) {
      return {'login_status': 'FAILED', 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      _user = null;
      _clearState();
      notifyListeners();
    }
  }
}
