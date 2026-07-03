import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportContactCard extends StatelessWidget {
  const SupportContactCard({super.key});

  // Mizan PLC Official Support Numbers
  final String supportOne = "0962274450";
  final String supportTwo = "0936262387";

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $phoneNumber';
      }
    } catch (e) {
      debugPrint("Dialer error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent, size: 48, color: Color(0xFF1B5E20)),
            const SizedBox(height: 12),
            const Text(
              "የሚዛን ድጋፍ ሰጪ (Mizan Support)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "ለማንኛውም እርዳታ ይደውሉልን\nCall us for any assistance",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Support Line 1
            _buildCallButton(
              context,
              label: "Support Line 1",
              number: supportOne,
              icon: Icons.phone,
            ),

            const SizedBox(height: 12),

            // Support Line 2
            _buildCallButton(
              context,
              label: "Support Line 2",
              number: supportTwo,
              icon: Icons.phone_android,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(BuildContext context,
      {required String label, required String number, required IconData icon}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _makePhoneCall(number),
        icon: Icon(icon, color: const Color(0xFF1B5E20)),
        label: Text("$label: $number"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Color(0xFF1B5E20)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
