import 'package:flutter/material.dart';

class AgentListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  const AgentListingCard(
      {super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String status = listing['status'] ?? 'pending';

    // UI logic for the badge
    Color badgeColor;
    String statusText;

    switch (status) {
      case 'active':
        badgeColor = const Color(0xFF1B5E20);
        statusText = "LIVE / ACTIVE";
        break;
      case 'pending_verification':
        badgeColor = Colors.orange[800]!;
        statusText = "PENDING PAYMENT";
        break;
      case 'rejected':
        badgeColor = Colors.red[700]!;
        statusText = "REJECTED";
        break;
      default:
        badgeColor = Colors.grey;
        statusText = "DRAFT";
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      listing['title'] ?? 'Untitled Listing',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${listing['quantity']} Units @ ${listing['unit_price']} ETB",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    listing['location'] ?? 'No location',
                    style: const TextStyle(
                        fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
