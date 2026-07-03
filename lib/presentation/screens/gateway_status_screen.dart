import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GatewayStatusScreen extends StatefulWidget {
  const GatewayStatusScreen({super.key});

  @override
  State<GatewayStatusScreen> createState() => _GatewayStatusScreenState();
}

class _GatewayStatusScreenState extends State<GatewayStatusScreen> {
  static const _platform = MethodChannel('com.mizan.gateway/sms_role');
  bool _isProcessing = false;
  bool _isAuthorized = false;

  Future<void> _handleAuthorization() async {
    setState(() => _isProcessing = true);
    try {
      // Request Default SMS Role (Android 16 Requirement)
      final dynamic result = await _platform.invokeMethod(
        'requestDefaultSmsRole',
      );

      if (result == "ALREADY_DEFAULT" || result == "REQUEST_SENT") {
        setState(() => _isAuthorized = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("MIZAN NATIVE RELAY ACTIVE"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      _showErrorDialog(e.message ?? "Permission Error");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B110F),
        title: const Text(
          "Permission Required",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Android 16: Ensure 'Allow Restricted Settings' is enabled.\n\n$message",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "GOT IT",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E2723), Color(0xFF1B110F)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAuthorized ? Icons.security : Icons.security_outlined,
              size: 100,
              color: _isAuthorized ? Colors.greenAccent : Colors.white24,
            ),
            const SizedBox(height: 30),
            const Text(
              "MIZAN GATEWAY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "NATIVE RELAY V2026",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 40),
            if (_isProcessing)
              const CircularProgressIndicator(color: Colors.greenAccent)
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAuthorized
                      ? Colors.white10
                      : Colors.greenAccent,
                  foregroundColor: _isAuthorized
                      ? Colors.white38
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Icon(_isAuthorized ? Icons.check : Icons.bolt),
                label: Text(
                  _isAuthorized ? "GATEWAY READY" : "AUTHORIZE RELAY",
                ),
                onPressed: _isAuthorized ? null : _handleAuthorization,
              ),
          ],
        ),
      ),
    );
  }
}
