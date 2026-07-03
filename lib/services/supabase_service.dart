import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Login logic for both Admin and Agents
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ADMIN ONLY: Registering a new agent
  // To keep Admin logged in, we use a custom metadata approach
  // and ensure "Email Confirmation" is OFF in Supabase Dashboard.
  Future<void> registerAgent({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // 1. Create the Auth User
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName}, // Initial metadata
    );

    if (response.user != null) {
      // 2. Insert into your public.profiles table
      // Matches your SQL: id, full_name, role, is_admin
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'role': 'agent',
        'is_admin': false,
        'wallet_balance': 0.00,
      });
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};
    return await _supabase.from('profiles').select().eq('id', user.id).single();
  }
}
