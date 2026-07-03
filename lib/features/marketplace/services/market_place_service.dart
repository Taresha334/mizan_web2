// filepath: lib/features/marketplace/services/market_place_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceService {
  final _supabase = Supabase.instance.client;

  /// Optimized stream for Mizan Marketplace.
  /// Strictly filters for visibility: Approved, Not Sold, and Not Expired.
  Stream<List<Map<String, dynamic>>> getActiveMarketListings({
    String? categoryId,
  }) {
    return _supabase
        .from('market_listings')
        .stream(primaryKey: ['id'])
        // Fixed: Use 'ascending: false' for descending order in streams
        .order('created_at', ascending: false)
        .map((data) {
          final now = DateTime.now().toUtc().toIso8601String();

          return data.where((item) {
            final String status =
                item['status']?.toString().toLowerCase().trim() ?? 'pending';
            final bool isSoldFlag = item['is_sold'] == true;

            // Check expiration
            final String? expiresAt = item['tier_expires_at'];
            final bool isNotExpired =
                expiresAt != null && expiresAt.compareTo(now) > 0;

            // Visibility Logic: Must be approved AND not sold AND not expired.
            final bool isVisible =
                status == 'approved' && !isSoldFlag && isNotExpired;

            // Category filter logic
            final bool matchesCategory =
                categoryId == null ||
                item['category_id']?.toString() == categoryId.toString();

            return isVisible && matchesCategory;
          }).toList();
        });
  }

  /// DIRECT AGENT ACTION: Updates status to 'sold' immediately.
  /// This removes the item from the public 'Active' stream.
  Future<void> updateSoldStatus(String id, bool isNowSold) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _supabase
          .from('market_listings')
          .update({
            'is_sold': isNowSold,
            'status': isNowSold ? 'sold' : 'approved',
            'sold_at': isNowSold ? now : null,
            'updated_at': now,
          })
          .eq('id', id);
    } catch (e) {
      _logError("updateSoldStatus", e);
      rethrow;
    }
  }

  /// Fetches a single listing with its category details joined.
  Future<Map<String, dynamic>?> getListingDetails(String id) async {
    try {
      return await _supabase
          .from('market_listings')
          .select('''
            *,
            market_categories (
              name,
              unit_label
            )
          ''')
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      _logError("getListingDetails", e);
      return null;
    }
  }

  void _logError(String method, Object e) {
    if (kDebugMode) {
      print("Mizan Marketplace Error [$method]: $e");
    }
  }
}
