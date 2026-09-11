import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/auth/auth_provider.dart';
import 'package:smileon/core/auth/auth_state.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isAgreed = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSuccess() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScaffold()),
      (route) => false,
    );
  }

  Future<void> _handleRegisterWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap setujui Syarat dan Ketentuan.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Register seamlessly with Google / Dynamic convention
      await ref.read(authProvider.notifier).loginWithGoogle(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
          );
      _onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendaftaran gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignup() async {
    ref.read(authServiceProvider).showDynamicAuth();
  }

  Future<void> _handleWalletSignup() async {
    ref.read(authServiceProvider).showDynamicAuth();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSessionModel?>>(authProvider, (previous, next) {
      next.whenData((session) {
        if (session != null) {
          _onSuccess();
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF2B2B2B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo SmileOn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'smile',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1E22),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRose,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'on',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Title
                        const Text(
                          'Create Your Account!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E22),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Join SmileOn to save your memories forever onchain.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Quick buttons: Google & Wallet
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _handleGoogleSignup,
                                icon: const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4285F4))),
                                label: const Text('Google', style: TextStyle(fontSize: 13, color: Color(0xFF1E1E22), fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _handleWalletSignup,
                                icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF1E1E22)),
                                label: const Text('Wallet', style: TextStyle(fontSize: 13, color: Color(0xFF1E1E22), fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or register with email', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                            ),
                            Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'e.g. Sarah Putri',
                          icon: Icons.person_outline,
                          validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                        ),

                        const SizedBox(height: 12),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'e.g. sarah@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Email wajib diisi';
                            if (!val.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Minimal 6 karakter',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF9E9E9E),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password wajib diisi';
                            if (val.length < 6) return 'Password minimal 6 karakter';
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // Terms Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _isAgreed,
                                activeColor: AppTheme.primaryRose,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setState(() => _isAgreed = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'I agree to SmileOn Terms of Service and Privacy Policy.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _handleRegisterWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRose,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),

                        const SizedBox(height: 16),

                        // Already have an account? Login
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: AppTheme.primaryRose,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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

            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRose),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryRose, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
