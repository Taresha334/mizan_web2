import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfile {
  final String id;
  final String fullName;
  final String role;

  AdminProfile({required this.id, required this.fullName, required this.role});

  // Factory to create a profile from Supabase data
  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      id: map['id'],
      fullName: map['full_name'] ?? 'mizan web',
      role: map['role'] ?? 'admin',
    );
  }
}

// Logic to fetch the logged-in admin's info
Future<AdminProfile?> getCurrentProfile() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return AdminProfile.fromMap(data);
}
