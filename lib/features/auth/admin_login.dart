// filepath: lib/features/auth/admin_login.dart
// MIZAN CORE: RESILIENT LOGIN GATE (V2026.4)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../admin/providers/auth_provider.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locController = TextEditingController();
  final _payRefController = TextEditingController();

  final List<String> _selectedExpertise = [];
  final List<String> _expertiseOptions = [
    'Farmer',
    'Veterinary Doctor',
    'Animal Feed Producer',
    'Agricultural Agent',
    'Broker',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _locController.dispose();
    _payRefController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack("Please enter both email and password", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // Use maybeSingle to prevent PGRST116 Crash
        final userData = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (!mounted) return;

        if (userData == null) {
          _showSnack(
            "Profile not found. Please contact Mizan Admin.",
            Colors.red,
          );
          await _supabase.auth.signOut();
          return;
        }

        final String role = userData['role'] ?? 'user';
        _routeByRole(role);
      }
    } on AuthException catch (e) {
      _showSnack(e.message, Colors.red);
    } catch (e) {
      _showSnack("Mizan System Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _routeByRole(String role) {
    if (role == 'admin') {
      context.go('/admin');
    } else if (role == 'agent') {
      context.go('/agent-portal');
    } else {
      context.go('/');
    }
  }

  Future<void> _handleApply() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpertise.isEmpty) {
      _showSnack("Please select at least one expertise", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('agent_applications').insert({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locController.text.trim(),
        'expertise': _selectedExpertise,
        'payment_ref': _payRefController.text.trim(),
        'status': 'pending',
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      _showSnack("Submission Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(
          Icons.check_circle,
          color: Color(0xFF1B5E20),
          size: 60,
        ),
        content: const Text(
          "Request Sent!\n\nMizan Admin will review your payment. Once approved, you will receive login credentials via SMS.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isLoginMode = true);
            },
            child: const Text(
              "BACK TO LOGIN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.agriculture,
                    size: 80,
                    color: Color(0xFF1B5E20),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "MIZAN PORTAL",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildToggle(),
                  const SizedBox(height: 32),
                  if (_isLoginMode)
                    ..._buildLoginFields()
                  else
                    ..._buildApplyFields(l10n),
                  const SizedBox(height: 32),
                  _buildMainButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleItem(
            "Sign In",
            _isLoginMode,
            () => setState(() => _isLoginMode = true),
          ),
          _toggleItem(
            "Apply to Join",
            !_isLoginMode,
            () => setState(() => _isLoginMode = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1B5E20) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginFields() {
    return [
      TextField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: "Email Address",
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: "Password",
          prefixIcon: const Icon(Icons.lock_outline),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildApplyFields(AppLocalizations l10n) {
    return [
      _applyField(_nameController, "Full Name", Icons.person_outline),
      const SizedBox(height: 16),
      _applyField(
        _phoneController,
        "Phone Number",
        Icons.phone_android,
        isPhone: true,
      ),
      const SizedBox(height: 16),
      _applyField(
        _locController,
        "Location/Region",
        Icons.location_on_outlined,
      ),
      const SizedBox(height: 16),
      _applyField(
        _payRefController,
        "Payment Reference (500 ETB)",
        Icons.receipt_long,
      ),
    ];
  }

  Widget _applyField(
    TextEditingController c,
    String l,
    IconData i, {
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i, size: 20),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
        ),
        onPressed: _isLoading
            ? null
            : (_isLoginMode ? _handleSignIn : _handleApply),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isLoginMode ? "SIGN IN" : "SUBMIT APPLICATION",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
