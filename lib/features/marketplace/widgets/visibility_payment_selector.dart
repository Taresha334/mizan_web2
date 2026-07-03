// filepath: lib/features/marketplace/widgets/visibility_payment_selector.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../marketplace/visibility_tier.dart';

class VisibilityPaymentSelector extends StatefulWidget {
  final String
  userRole; // Pass 'partner' or 'non-partner' based on active user profile
  final Function(VisibilityTier selectedTier) onTierSelected;

  const VisibilityPaymentSelector({
    super.key,
    required this.userRole,
    required this.onTierSelected,
  });

  @override
  State<VisibilityPaymentSelector> createState() =>
      _VisibilityPaymentSelectorState();
}

class _VisibilityPaymentSelectorState extends State<VisibilityPaymentSelector> {
  final _supabase = Supabase.instance.client;
  VisibilityTier? _selectedTier;

  @override
  Widget build(BuildContext context) {
    final String cleanRole = widget.userRole.toLowerCase().trim();

    return FutureBuilder<List<Map<String, dynamic>>>(
      // Dynamically queries the exact row entries managed by the Admin pricing engine
      future: _supabase
          .from('visibility_pricing')
          .select()
          .eq('user_role', cleanRole),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          // Robust system fallback if database seeds aren't fully deployed yet
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Standard posting active. Standard visibility rates apply.",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }

        final tiers = snapshot.data!
            .map((m) => VisibilityTier.fromMap(m))
            .toList();

        // Sort items logically by duration length
        tiers.sort((a, b) => a.weeks.compareTo(b.weeks));

        // Auto-select shortest option initially if none chosen yet
        if (_selectedTier == null && tiers.isNotEmpty) {
          _selectedTier = tiers.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onTierSelected(_selectedTier!);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Marketplace Visibility Horizon",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...tiers.map((tier) {
              final bool isSelected = _selectedTier?.id == tier.id;
              return Card(
                elevation: isSelected ? 2 : 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  activeColor: const Color(0xFF1B5E20),
                  title: Text(
                    "${tier.durationCategory} Plan (${tier.weeks} ${tier.weeks == 1 ? 'Week' : 'Weeks'})",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    "Optimized distribution channel rate for ${cleanRole.toUpperCase()} accounts",
                    style: const TextStyle(fontSize: 11),
                  ),
                  secondary: Text(
                    "${tier.priceEtb.toStringAsFixed(0)} ETB",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20),
                      fontSize: 15,
                    ),
                  ),
                  value: tier.id,
                  groupValue: _selectedTier?.id,
                  onChanged: (val) {
                    setState(() {
                      _selectedTier = tiers.firstWhere((t) => t.id == val);
                    });
                    widget.onTierSelected(_selectedTier!);
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
