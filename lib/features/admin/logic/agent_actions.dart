// lib/features/admin/logic/agent_actions.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Approves an agent application and promotes them to a professional Profile.
/// Now supports manual coordinate injection from the Admin Geo-Validator.
Future<void> approveAgent(
  Map<String, dynamic> application, {
  String? customEmail,
  String? customPass,
  double? lat, // New: Validated Latitude from Admin Map
  double? lng, // New: Validated Longitude from Admin Map
}) async {
  final supabase = Supabase.instance.client;

  // 1. Resolve Credentials
  // Prioritize Admin-edited values from the dialog, fallback to phone-based logic.
  final finalEmail = customEmail ?? "${application['phone']}@mizan.et";
  final finalPass = customPass ?? "Mizan2026!";

  // 2. Resolve Geography
  // Hierarchy: 1. Admin's manual pin (lat) -> 2. Applicant's GPS -> 3. Fail (Error)
  final finalLat = lat ?? application['latitude'];
  final finalLng = lng ?? application['longitude'];

  if (finalLat == null || finalLng == null) {
    throw Exception(
      "Geographic coordinates are missing. Please pin the location on the map.",
    );
  }

  try {
    // 3. Invoke the Edge Function 'create-agent'
    // This function handles: Auth User creation, Profile insertion, and Application status update.
    final response = await supabase.functions.invoke(
      'create-agent',
      body: {
        'email': finalEmail.trim().toLowerCase(),
        'password': finalPass.trim(),
        'username': application['full_name'] ?? "Mizan Partner",
        'phone': application['phone'],
        'category': application['category'] ?? 'agent',
        'city_name': application['location'] ?? "Unknown City",
        'latitude': finalLat,
        'longitude': finalLng,
        // Optional: Pass the original application ID so the Edge Function can mark it 'approved'
        'application_id': application['id'],
      },
    );

    // 4. Handle Response Integrity
    if (response.status != 200 && response.status != 201) {
      final errorMsg = response.data is Map
          ? (response.data['error'] ?? "Server rejected the activation.")
          : "Server error during activation.";
      throw Exception(errorMsg);
    }
  } catch (e) {
    // If it's a Supabase error or network error, sanitize the message for the UI
    throw Exception(
      "Activation Failed: ${e.toString().replaceAll("Exception: ", "")}",
    );
  }
}
