// Login & Registration screen — Feature 2.0 Authentication Skeleton.
//
// Extracted from main.dart to avoid circular imports:
//   main.dart → screens/login_screen.dart → state/auth_state.dart  ✓
//
// On successful login: calls AuthState.login(), which triggers
// Consumer<AuthState> in FreezerPenguinApp to rebuild and show
// MainNavigationScreen without any explicit Navigator.push.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            isError ? Colors.red.shade700 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outline, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(l10n.loginErrorEmptyFields, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final endpoint = _isRegistering ? 'register' : 'login';
      final uri = Uri.parse('$backendUrl/auth/$endpoint');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (_isRegistering) {
        if (response.statusCode == 201) {
          _showSnackBar(l10n.registerSuccess);
          setState(() {
            _isRegistering = false;
            _passwordController.clear();
          });
        } else {
          _showSnackBar(
            body['detail']?.toString() ?? l10n.loginErrorInvalid,
            isError: true,
          );
        }
      } else {
        if (response.statusCode == 200) {
          context.read<AuthState>().login(
                userId: body['user_id'] as int,
                email: body['email'] as String,
                token: body['access_token'] as String,
              );
          // No Navigator.push needed — Consumer<AuthState> in
          // FreezerPenguinApp auto-swaps LoginScreen for MainNavigationScreen.
        } else {
          _showSnackBar(
            body['detail']?.toString() ?? l10n.loginErrorInvalid,
            isError: true,
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Connection failed. Check your network and try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Brand mark ───────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.outline, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.ac_unit,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  style: GoogleFonts.quicksand(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeMsg,
                  style: GoogleFonts.quicksand(
                    color: AppColors.textVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Form card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border.all(color: AppColors.outline, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRegistering
                            ? l10n.registerTitle
                            : l10n.loginTitle,
                        style: GoogleFonts.quicksand(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email field
                      Text(
                        l10n.loginEmailLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _emailController,
                        hint: 'penguin@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      Text(
                        l10n.loginPasswordLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passwordController,
                        hint: '••••••••',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textVariant,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit button / loading indicator
                      SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 10),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(
                                      color: AppColors.outline,
                                      width: 2,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _isRegistering
                                      ? l10n.registerTitle
                                      : l10n.loginTitle,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Toggle login ↔ register ───────────────────────────────
                GestureDetector(
                  onTap: () => setState(() {
                    _isRegistering = !_isRegistering;
                    _emailController.clear();
                    _passwordController.clear();
                  }),
                  child: Text(
                    _isRegistering
                        ? l10n.switchToLogin
                        : l10n.switchToRegister,
                    style: GoogleFonts.quicksand(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textVariant),
        filled: true,
        fillColor: AppColors.surfaceLowest,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
    );
  }
}
