import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      context.go('/complete-profile');
    } on FirebaseAuthException catch (e) {
      debugPrint("Registration Error: ${e.code} - ${e.message}");
      if (e.code == 'email-already-in-use') {
        _showSnackBar("Email is already in use. Please log in.");
      } else if (e.code == 'invalid-email') {
        _showSnackBar("Please enter a valid email address.");
      } else {
        _showSnackBar(e.message ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint("Unexpected Registration Exception: $e");
      _showSnackBar("An unexpected error occurred.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'logo_text',
                child: Text(
                  'Join Habesha Dates',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your premium account to start matching with your soulmate.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 40),
              
              _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscureText: true),
              const SizedBox(height: 16),
              _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_reset_outlined, obscureText: true),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.white54),
                      children: [
                        TextSpan(
                          text: "Log in",
                          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
