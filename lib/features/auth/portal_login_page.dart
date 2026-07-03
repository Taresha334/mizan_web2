// filepath: lib/features/auth/portal_login_page.dart
// MIZAN PORTAL: SYSTEMIC AUTH PORTAL INTERFACE (V11.3.5 - ULTRA-STABLE MOBILE DECOUPLED MASTER)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class PortalLoginPage extends StatefulWidget {
  const PortalLoginPage({super.key});

  @override
  State<PortalLoginPage> createState() => _PortalLoginPageState();
}

class _PortalLoginPageState extends State<PortalLoginPage> {
  final _identifierController = TextEditingController();
  final _credentialController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isFarmerMode = true;

  final Color mizanGreen = const Color(0xFF1B5E20);

  @override
  void dispose() {
    _identifierController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final identifier = _identifierController.text.trim();
    final credential = _credentialController.text.trim();

    if (identifier.isEmpty || credential.isEmpty) {
      _showSnack(
        _isFarmerMode
            ? "እባክዎ ስልክ ቁጥር እና ባለ 4-አሃዝ የይለፍ ቃል ያስገቡ"
            : "Please enter credentials",
        Colors.orange.shade900,
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isFarmerMode) {
        final result = await authProvider.signInFarmerWithPin(
          identifier,
          credential,
        );
        final String status = result['login_status'] ?? 'FAILED';

        if (status == 'SUCCESS') {
          await authProvider.synchronizeProfileMetadata();
          if (!mounted) return;

          _showSnack(
            "እንኳን ደህና መጡ ${authProvider.customName ?? result['full_name'] ?? 'User'}!",
            mizanGreen,
          );

          String parsedRole = 'agent';
          if (authProvider.customRole != null &&
              authProvider.customRole != 'null' &&
              authProvider.customRole!.isNotEmpty) {
            parsedRole = authProvider.customRole!;
          } else if (result['user_role'] != null) {
            parsedRole = result['user_role'];
          }

          _navigateByRole(parsedRole);
        } else {
          _showSnack("የመግባት ሂደት አልተሳካም:: እንደገና ይሞክሩ::", Colors.red.shade900);
        }
      } else {
        final user = await authProvider.signIn(identifier, credential);

        if (user != null) {
          await authProvider.synchronizeProfileMetadata();
          if (!mounted) return;

          String parsedRole = 'admin';
          if (authProvider.customRole != null &&
              authProvider.customRole != 'null' &&
              authProvider.customRole!.isNotEmpty) {
            parsedRole = authProvider.customRole!;
          }

          _navigateByRole(parsedRole);
        } else {
          _showSnack(
            "Login failed. Check admin credentials and retry.",
            Colors.red.shade900,
          );
        }
      }
    } on AuthException catch (e) {
      _showSnack(e.message, Colors.red.shade900);
    } catch (e) {
      _showSnack(
        "Login connection timeout. Verify parameters and retry.",
        Colors.red.shade900,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByRole(String role) {
    if (!mounted) return;

    final cleanRole = role.toLowerCase().trim();
    debugPrint(
      "MIZAN WEB REDIRECT ENGINE: Parsing target routing pointer: '$cleanRole'",
    );

    if (cleanRole == 'admin') {
      context.go('/admin/approvals');
    } else if (cleanRole == 'partner' ||
        cleanRole == 'agent' ||
        cleanRole == 'farmer' ||
        cleanRole == 'vet') {
      context.go('/post-product');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      // STABILIZER ONE: Stop the phone keyboard from forcing canvas recalculation passes
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double cardWidth = constraints.maxWidth > 480
              ? 480
              : constraints.maxWidth * 0.92;

          bool isCompactMobile = cardWidth < 380;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.agriculture, size: 64, color: mizanGreen),
                    const SizedBox(height: 12),
                    Text(
                      "MIZAN PORTAL",
                      style: TextStyle(
                        fontSize: 22,
                        // STABILIZER TWO: Normalized heavy weights to limit rendering lag
                        fontWeight: FontWeight.bold,
                        color: mizanGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildUnifiedWorkspaceTabs(isCompactMobile),
                    const SizedBox(height: 24),
                    _buildTextField(
                      _identifierController,
                      _isFarmerMode
                          ? "የስልክ ቁጥር (Phone Number)"
                          : "Admin Email Address",
                      _isFarmerMode
                          ? Icons.phone_android_rounded
                          : Icons.email_rounded,
                      _isFarmerMode,
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 24),
                    _buildSignInButton(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/application-status'),
                      icon: const Icon(Icons.manage_search_rounded, size: 20),
                      label: const Text("Check My Application Status"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mizanGreen,
                        side: BorderSide(
                          color: mizanGreen.withOpacity(0.35),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        "BACK TO MIZAN HOME",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedWorkspaceTabs(bool isCompactMobile) {
    // STABILIZER THREE: Added hard locked constraints around the container height to absorb layouts perfectly
    return SizedBox(
      height: 48,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _WorkspaceTabItem(
                label: "አርሶ አደር/ወኪል",
                isActive: _isFarmerMode,
                isCompactMobile: isCompactMobile,
                onTap: () {
                  setState(() {
                    _isFarmerMode = true;
                    _identifierController.clear();
                    _credentialController.clear();
                  });
                },
                activeColor: mizanGreen,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _WorkspaceTabItem(
                label: "Admin Portal",
                isActive: !_isFarmerMode,
                isCompactMobile: isCompactMobile,
                onTap: () {
                  setState(() {
                    _isFarmerMode = false;
                    _identifierController.clear();
                    _credentialController.clear();
                  });
                },
                activeColor: mizanGreen,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _WorkspaceTabItem(
                label: "Apply to Join",
                isActive: false,
                isActionLink: true,
                isCompactMobile: isCompactMobile,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  context.go('/agent-application');
                },
                activeColor: mizanGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isNumeric,
  ) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      keyboardType: isNumeric
          ? TextInputType.phone
          : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: mizanGreen, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _credentialController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      keyboardType: _isFarmerMode ? TextInputType.number : TextInputType.text,
      maxLength: _isFarmerMode ? 4 : null,
      decoration: InputDecoration(
        labelText: _isFarmerMode ? "ባለ 4-አሃዝ የይለፍ ቃል (PIN)" : "Password",
        labelStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        counterText: "",
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: mizanGreen,
          size: 20,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            size: 18,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: mizanGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: _isLoading ? null : _handleSignIn,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "ENTER PORTAL",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  void _showSnack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          m,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _WorkspaceTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isActionLink;
  final bool isCompactMobile;

  const _WorkspaceTabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    this.isActionLink = false,
    required this.isCompactMobile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: isCompactMobile ? 1 : 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCompactMobile ? 10.0 : 11.5,
            fontWeight: FontWeight.bold,
            color: isActive
                ? activeColor
                : (isActionLink ? Colors.blueGrey.shade800 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
