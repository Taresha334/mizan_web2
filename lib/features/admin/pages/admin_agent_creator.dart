// filepath: lib/features/admin/pages/admin_agent_creator.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// Import your SMS utility
import '../utils/mizan_sms_launcher.dart';

class AdminAgentCreator extends StatefulWidget {
  const AdminAgentCreator({super.key});

  @override
  State<AdminAgentCreator> createState() => _AdminAgentCreatorState();
}

class _AdminAgentCreatorState extends State<AdminAgentCreator> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isLoading = false;
  bool _isLocating = false;
  String _selectedCategory = 'agent';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });
        _showSnackBar("GPS Coordinates Captured!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Location Error: $e", Colors.orange);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _handleAdminCreate() async {
    final String name = _nameController.text.trim();
    final String city = _cityController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String phone = _phoneController.text.trim();

    if (name.isEmpty ||
        city.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty) {
      _showSnackBar(
        "All fields marked with * and Phone Number are required",
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? lat = double.tryParse(_latController.text);
      double? lng = double.tryParse(_lngController.text);

      if (lat == null || lng == null) {
        List<Location> locations = await locationFromAddress("$city, Ethiopia");
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        } else {
          throw Exception("Could not verify coordinates for this city.");
        }
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create-agent',
        body: {
          'email': email,
          'password': password,
          'username': name,
          'phone': phone,
          'city_name': city,
          'latitude': lat,
          'longitude': lng,
          'category': _selectedCategory,
          'role': 'agent',
          'is_verified': true,
        },
      );

      if (response.status == 200 || response.status == 201) {
        // 1. Logic: Prepare the Welcome Message for the Partner
        final String welcomeMsg =
            "Mizan PLC: Welcome $name!\n"
            "Your Partner account is active.\n"
            "Email: $email\n"
            "Pass: $password\n"
            "Portal: https://mizan-market-et.vercel.app";

        // 2. Logic: Launch personal SMS app to send credentials
        await MizanSmsLauncher.launchNativeSMS(
          recipients: [phone],
          message: welcomeMsg,
        );

        _showSnackBar("Mizan Account Activated & SMS Prepared!", Colors.green);
        _clearForm();
      } else {
        throw Exception(response.data['error'] ?? "Failed to create account");
      }
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _cityController.clear();
    _latController.clear();
    _lngController.clear();
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Staff Registration",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Assign New Mizan Partner",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  _nameController,
                  "Full Name *",
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _cityController,
                        "Target City *",
                        Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _isLocating ? null : _getCurrentLocation,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFC6A664),
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _latController,
                        "Latitude",
                        Icons.map_outlined,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _lngController,
                        "Longitude",
                        Icons.explore_outlined,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Partner Category",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'agent',
                      child: Text("Agricultural Agent"),
                    ),
                    DropdownMenuItem(
                      value: 'vet',
                      child: Text("Veterinary Doctor"),
                    ),
                    DropdownMenuItem(
                      value: 'worker',
                      child: Text("Labour Worker"),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _phoneController,
                  "Phone Number *",
                  Icons.phone_android_outlined,
                  isNumber: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _emailController,
                  "Login Email *",
                  Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  "Temporary Password *",
                  Icons.lock_reset_outlined,
                  isObscure: true,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handleAdminCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "ACTIVATE PARTNER ACCOUNT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
      ),
    );
  }
}
