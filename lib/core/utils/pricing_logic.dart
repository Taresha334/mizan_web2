import 'package:flutter/foundation.dart';

class MizanPricing {
  /// Visibility Fee logic for the Mizan Marketplace.
  /// Standardizes fees across Non-Partners, Partners, and Admins.
  static double getVisibilityFee({
    required String role,
    required int weeks,
    required bool isRegisteredPartner,
  }) {
    // Safety check: minimum 1 week billing
    final effectiveWeeks = weeks < 1 ? 1 : weeks;
    final normalizedRole = role.trim().toLowerCase();

    // 1. NON-PARTNER (One-off Users / Farmers / Traders)
    if (!isRegisteredPartner) {
      if (effectiveWeeks <= 1) return 5.0;
      if (effectiveWeeks <= 2) return 8.0;
      return 12.0;
    }

    // 2. INTERNAL MIZAN ACCOUNTS (Admin / Factory)
    if (normalizedRole == 'admin' || normalizedRole == 'mizan') {
      if (effectiveWeeks <= 1) return 3.0;
      if (effectiveWeeks <= 2) return 5.0;
      return 8.0;
    }

    // 3. REGISTERED PARTNERS (Agents, Vets, Partners)
    // Discounted to reward membership/loyalty
    if (effectiveWeeks <= 1) return 2.0;
    if (effectiveWeeks <= 2) return 3.0;
    return 5.0;
  }

  /// Registration Fee: For users upgrading to "Partner" status.
  static double getAgentRegistrationFee({required int weeks}) {
    if (weeks <= 4) return 1.0; // 1 Month Standard
    if (weeks <= 24) return 4.0; // 6 Months Bulk
    if (weeks <= 52) return 7.0; // 1 Year Premium
    return weeks * 0.15; // Enterprise Custom
  }
}
