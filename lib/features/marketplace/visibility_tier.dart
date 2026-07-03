// filepath: lib/features/marketplace/models/visibility_tier.dart

class VisibilityTier {
  final String id;
  final String durationCategory;
  final int weeks;
  final String userRole;
  final double priceEtb;

  VisibilityTier({
    required this.id,
    required this.durationCategory,
    required this.weeks,
    required this.userRole,
    required this.priceEtb,
  });

  factory VisibilityTier.fromMap(Map<String, dynamic> map) {
    return VisibilityTier(
      id: map['id'] ?? '',
      durationCategory: map['duration_category'] ?? 'Standard',
      weeks: (map['weeks'] ?? 1) as int,
      userRole: map['user_role'] ?? 'non-partner',
      priceEtb: (map['price_etb'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
