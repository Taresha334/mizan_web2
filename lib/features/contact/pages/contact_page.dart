import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse("tel:${phone.replaceAll(' ', '')}");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildContactHeader(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 60, horizontal: 100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Get in Touch",
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20))),
                        const SizedBox(height: 20),
                        const Text(
                            "Our experts are ready to assist you with feed formulation and farm management questions."),
                        const SizedBox(height: 40),
                        _contactCard(
                          icon: Icons.phone,
                          title: "Call our Office",
                          content: "+251 962 27 44 50\n+251 936 26 23 87",
                          onTap: () => _makeCall("+251962274450"),
                        ),
                        _contactCard(
                          icon: Icons.location_on,
                          title: "Visit Us",
                          content: "Mizan PLC Headquarters\nAdama, Ethiopia",
                          onTap: () {},
                        ),
                        _contactCard(
                          icon: Icons.email,
                          title: "Email Support",
                          content: "info@mizanplc.com",
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 100),
                  // Inquiry Form Column
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20)
                        ],
                      ),
                      child: Column(
                        children: [
                          const TextField(
                              decoration: InputDecoration(
                                  labelText: "Your Name",
                                  border: OutlineInputBorder())),
                          const SizedBox(height: 20),
                          const TextField(
                              decoration: InputDecoration(
                                  labelText: "Phone Number",
                                  border: OutlineInputBorder())),
                          const SizedBox(height: 20),
                          const TextField(
                              maxLines: 4,
                              decoration: InputDecoration(
                                  labelText: "How can we help your farm?",
                                  border: OutlineInputBorder())),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20)),
                              onPressed: () {},
                              child: const Text("Send Message",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeader() {
    return Container(
      width: double.infinity,
      height: 300,
      color: const Color(0xFF1B5E20),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("CONTACT US",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4)),
            SizedBox(height: 10),
            Text("Your partners in scientific livestock nutrition",
                style: TextStyle(color: Colors.white70, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(
      {required IconData icon,
      required String title,
      required String content,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(content, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
