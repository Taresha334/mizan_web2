// filepath: lib/features/farmers/pages/agent_application_form.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mizan_web/features/farmers/pages/mizan_agent_map_page.dart';

class AgentApplicationForm extends StatefulWidget {
  const AgentApplicationForm({super.key});

  @override
  State<AgentApplicationForm> createState() => _AgentApplicationFormState();
}

class _AgentApplicationFormState extends State<AgentApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _paymentRefController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _selectedCategoryKey;
  Map<String, dynamic>? _selectedTier;
  bool _isSubmitting = false;
  final Color mizanGreen = const Color(0xFF1B5E20);

  // Mapped to exact DB values for custom_role consistency
  final Map<String, String> _categoryOptions = {
    'Agricultural Agent / Agro-Dealer': 'agent',
    'Veterinary Doctor / AI Technician': 'vet',
    'Labour Worker / Farm Manager': 'worker',
    'Farmer / Seed Multiplier': 'farmer',
    'Agricultural-Pharmacist / Agronomist': 'specialist',
    'Logistics / Post-Harvest Expert': 'logistics',
    'Other Agricultural Partner': 'others',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => const MizanAgentMapPage(isPickerMode: true),
      ),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationController.text =
            "${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}";
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() ||
        _selectedTier == null ||
        _latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete all fields, location, and tier."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _supabase.functions.invoke(
        'verify-mizan-payment',
        body: {
          'tx_id': _paymentRefController.text.trim().toUpperCase(),
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'category':
              _selectedCategoryKey, // This maps to 'vet', 'farmer', etc.
          'requested_weeks': (_selectedTier!['duration_weeks'] as num).toInt(),
          'latitude': _latitude,
          'longitude': _longitude,
        },
      );

      if (response.data['success'] == true) {
        if (mounted) _showSuccessDialog();
      } else {
        throw Exception(response.data['error'] ?? 'Registration rejected.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Success"),
      content: const Text(
        "Your payment is verified. Credentials sent via SMS.",
      ),
      actions: [
        TextButton(
          onPressed: () => context.go('/post-product'),
          child: const Text("OK"),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text("PARTNER APPLICATION"),
        backgroundColor: mizanGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_nameController, "Full Name", Icons.person),
              _buildField(
                _phoneController,
                "Telebirr Phone",
                Icons.phone,
                isPhone: true,
              ),
              _buildField(
                _locationController,
                "District Address",
                Icons.map,
                isMapField: true,
              ),
              _buildCategoryDropdown(),
              _buildTierStream(),
              const SizedBox(height: 20),
              _buildField(
                _paymentRefController,
                "Telebirr TxID",
                Icons.receipt_long,
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      value: _selectedCategoryKey,
      items: _categoryOptions.entries
          .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryKey = v),
      decoration: InputDecoration(
        labelText: "Category",
        prefixIcon: Icon(Icons.category, color: mizanGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v == null ? "Select a category" : null,
    ),
  );

  Widget _buildTierStream() => StreamBuilder<List<Map<String, dynamic>>>(
    stream: _supabase
        .from('registration_pricing')
        .stream(primaryKey: ['id'])
        .order('duration_weeks'),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      return Column(
        children: snapshot.data!
            .map(
              (t) => RadioListTile(
                title: Text(t['tier_name']),
                subtitle: Text("${t['price_etb']} ETB"),
                value: t['id'],
                groupValue: _selectedTier?['id'],
                onChanged: (v) => setState(() => _selectedTier = t),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _buildField(
    TextEditingController c,
    String l,
    IconData i, {
    bool isPhone = false,
    bool isMapField = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      readOnly: isMapField,
      onTap: isMapField ? _openMapPicker : null,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i, color: mizanGreen),
        suffixIcon: isMapField
            ? InkWell(
                onTap: _openMapPicker,
                child: const Icon(Icons.map, color: Colors.amber, size: 28),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: mizanGreen),
      onPressed: _isSubmitting ? null : _submitApplication,
      child: const Text(
        "SUBMIT APPLICATION",
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}
