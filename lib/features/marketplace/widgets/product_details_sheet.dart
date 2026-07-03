import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? profile;
  final Function(String? id, String? phone) onContact;

  const ProductDetailsSheet({
    super.key,
    required this.data,
    required this.profile,
    required this.onContact,
  });

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri url = Uri.parse("tel:${phoneNumber.trim()}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSold = (data['is_sold'] == true || data['status'] == 'sold');
    // Priority: listing specific contact -> profile contact
    final String phone =
        data['contact_phone']?.toString() ??
        profile?['phone_number']?.toString() ??
        '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // --- TOP FIXED SECTION (Always Visible) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  "${data['unit_price'] ?? '0'} ETB",
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFFC6A664),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.location_on_outlined,
                        "Location:",
                        data['location'] ?? "N/A",
                      ),
                    ),
                    IconButton(
                      onPressed: () => _makeCall(phone),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.phone_in_talk,
                          color: Color(0xFF1B5E20),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
              ],
            ),
          ),

          // --- SCROLLABLE SECTION ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  "Quantity:",
                  "${data['quantity'] ?? '0'} ${data['unit'] ?? ''}",
                ),
                const SizedBox(height: 20),
                const Text(
                  "Description",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? "No description provided.",
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // --- STICKY BOTTOM BUTTON ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSold ? Colors.grey : const Color(0xFF1B5E20),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: isSold ? null : () => _makeCall(phone),
              icon: const Icon(Icons.phone, color: Colors.white),
              label: Text(
                isSold ? "ALREADY SOLD" : "CALL TO ORDER",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
