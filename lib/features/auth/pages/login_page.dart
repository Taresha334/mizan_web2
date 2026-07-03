// filepath: lib/features/auth/agent_login_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mizan_web/core/l10n/app_localizations.dart';

class AgentLoginPage extends StatefulWidget {
  const AgentLoginPage({super.key});

  @override
  State<AgentLoginPage> createState() => _AgentLoginPageState();
}

class _AgentLoginPageState extends State<AgentLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // UI State
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locController = TextEditingController();
  final _payRefController = TextEditingController();

  // MIZAN STANDARDS
  String _selectedCategory = 'agent';
  final List<String> _selectedExpertise = [];

  final List<String> _expertiseOptions = [
    'Poultry Health',
    'Dairy Management',
    'Crop Protection',
    'Animal Feed Nutrition',
    'Market Brokering',
  ];

  @override
  void dispose() {
    for (var c in [
      _emailController,
      _passwordController,
      _nameController,
      _phoneController,
      _locController,
      _payRefController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // --- LOGIC: LOGIN ---
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack("Please enter both email and password", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) context.go('/agent-portal');
    } on AuthException catch (e) {
      _showSnack(e.message, Colors.red);
    } catch (e) {
      _showSnack("An unexpected error occurred", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: APPLICATION ---
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
        'category': _selectedCategory,
        'status': 'pending',
        'payment_status': 'pending',
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      _showSnack("Submission Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            // FIX: minHeight belongs inside BoxConstraints to allow scrolling
            constraints: BoxConstraints(minHeight: size.height),
            child: Container(
              width: size.width,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 20.0,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.agriculture,
                          size: 70,
                          color: Color(0xFF1B5E20),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "MIZAN PLC",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildToggle(),
                        const SizedBox(height: 30),

                        if (_isLoginMode)
                          ..._buildLoginFields()
                        else
                          ..._buildApplyFields(l10n),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : (_isLoginMode ? _handleLogin : _handleApply),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _isLoginMode
                                        ? "SIGN IN"
                                        : "SUBMIT APPLICATION",
                                    style: const TextStyle(
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _toggleItem(
            "LOGIN",
            _isLoginMode,
            () => setState(() => _isLoginMode = true),
          ),
          _toggleItem(
            "APPLY",
            !_isLoginMode,
            () => setState(() => _isLoginMode = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B5E20) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
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
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock_outline),
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
        "Location (City/Region)",
        Icons.location_on_outlined,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: "Join as:",
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'agent', child: Text("Agricultural Agent")),
          DropdownMenuItem(value: 'vet', child: Text("Veterinary Doctor")),
          DropdownMenuItem(value: 'worker', child: Text("Labour Worker")),
        ],
        onChanged: (v) => setState(() => _selectedCategory = v!),
      ),
      const SizedBox(height: 20),
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Expertise:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ..._expertiseOptions.map(
        (opt) => CheckboxListTile(
          title: Text(opt, style: const TextStyle(fontSize: 14)),
          value: _selectedExpertise.contains(opt),
          onChanged: (val) => setState(
            () => val!
                ? _selectedExpertise.add(opt)
                : _selectedExpertise.remove(opt),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
      ),
      const SizedBox(height: 16),
      _applyField(
        _payRefController,
        "Telebirr Transaction Ref",
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
        title: const Icon(
          Icons.check_circle,
          color: Color(0xFF1B5E20),
          size: 60,
        ),
        content: const Text(
          "Application Submitted!\nMizan Admin will review your payment and contact you shortly.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
