// filepath: lib/features/auth/pages/apply_to_join_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ApplyToJoinPage extends StatefulWidget {
  const ApplyToJoinPage({super.key});

  @override
  State<ApplyToJoinPage> createState() => _ApplyToJoinPageState();
}

class _ApplyToJoinPageState extends State<ApplyToJoinPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _paymentRefController = TextEditingController();

  bool _isLoading = false;
  String _selectedCategory = 'agent';
  final List<String> _selectedExpertise = [];

  final List<String> _expertiseOptions = [
    'Poultry Health',
    'Dairy Management',
    'Animal Feed Nutrition',
    'Market Linking',
    'Farm Design',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpertise.isEmpty) {
      _showSnackBar(
        "Please select at least one area of expertise",
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.from('agent_applications').insert({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'expertise': _selectedExpertise,
        'payment_ref': _paymentRefController.text.trim(),
        'status': 'pending',
        'payment_status': 'pending', // Will be updated by Admin or Webhook
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showSnackBar("Submission Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Application Submitted!\n\nMizan Admin will review your payment and contact you via SMS once activated.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text("RETURN TO LOGIN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mizanGreen = Color(0xFF1B5E20);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Mizan Partner Network"),
        backgroundColor: mizanGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Partner Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mizanGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, "Full Name", Icons.person),
              _buildTextField(
                _phoneController,
                "Phone Number",
                Icons.phone,
                isPhone: true,
              ),
              _buildTextField(
                _locationController,
                "City / Location",
                Icons.location_on,
              ),

              const SizedBox(height: 12),
              const Text(
                "Category",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['agent', 'vet', 'worker'].map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),
              const Text(
                "Areas of Expertise",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _expertiseOptions.map((expert) {
                  final isSelected = _selectedExpertise.contains(expert);
                  return FilterChip(
                    label: Text(expert),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        val
                            ? _selectedExpertise.add(expert)
                            : _selectedExpertise.remove(expert);
                      });
                    },
                  );
                }).toList(),
              ),

              const Divider(height: 40),
              _buildPaymentInstructions(),
              const SizedBox(height: 20),

              _buildTextField(
                _paymentRefController,
                "Telebirr Transaction Reference",
                Icons.receipt_long,
                helper: "Example: 1A2B3C4D",
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mizanGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SUBMIT APPLICATION",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Payment Instructions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "To activate your account, please pay the registration fee:",
          ),
          const SizedBox(height: 8),
          const Text(
            "• Telebirr Account: 0912345678",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text("• Account Name: Mizan PLC"),
          const Text("• Amount: 500 ETB"),
          const SizedBox(height: 10),
          Text(
            "After payment, enter the transaction reference below.",
            style: TextStyle(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPhone = false,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  void _showSnackBar(String msg, Color col) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: col));
  }
}
