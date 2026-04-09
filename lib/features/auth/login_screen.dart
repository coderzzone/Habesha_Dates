import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isEmailMode = false;
  String _verificationId = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 1. GOOGLE SIGN IN ---
  Future<void> _signInWithGmail() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.signInWithCredential(credential);
      _checkUserStatusAndNavigate();
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      _showSnackBar("Google Sign-In failed.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithTelegram() async {
    _showSnackBar("Telegram login is not configured yet.");
  }

  // --- 2. EMAIL & PASSWORD LOGIN ---
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _checkUserStatusAndNavigate();
    } on FirebaseAuthException catch (e) {
      debugPrint("Email Auth Error: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnackBar("Invalid email or password. Please try again.");
      } else {
        _showSnackBar(e.message ?? "Authentication failed");
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. PHONE AUTH LOGIC ---
  void _verifyPhoneNumber() async {
    final phoneNum = _phoneController.text.trim();
    if (phoneNum.isEmpty || phoneNum.length < 9) {
      _showSnackBar("Please enter a valid phone number");
      return;
    }
    
    setState(() => _isLoading = true);
    String phoneNumber = "+251$phoneNum";

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (cred) async {
          await _auth.signInWithCredential(cred);
          _checkUserStatusAndNavigate();
        },
        verificationFailed: (e) {
          debugPrint("Phone Auth Verification Failed: ${e.message}");
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar(e.message ?? "Verification failed");
          }
        },
        codeSent: (id, token) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verificationId = id;
            });
            _showOtpBottomSheet();
          }
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (e) {
      debugPrint("Phone Auth Exception: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Phone verification failed.");
      }
    }
  }

  void _showOtpBottomSheet() {
    final TextEditingController otpController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Verify Code",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We sent a 6-digit code to your phone",
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: "000000",
                hintStyle: const TextStyle(color: Colors.white10),
                fillColor: Colors.black26,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _verifyOtp(otpController.text),
                child: const Text("Verify & Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyOtp(String code) async {
    if (code.length != 6) {
      _showSnackBar("Please enter a 6-digit code");
      return;
    }
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await _auth.signInWithCredential(cred);
      if (mounted) {
        Navigator.pop(context);
        _checkUserStatusAndNavigate();
      }
    } catch (e) {
      _showSnackBar("Invalid Code. Please try again.");
    }
  }

  void _checkUserStatusAndNavigate() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        if (doc.exists) {
          context.go('/discovery');
        } else {
          context.go('/complete-profile');
        }
      }
    } catch (e) {
      debugPrint("Navigation Error: $e");
      _showSnackBar("Error during navigation.");
    }
  }

  void _showSnackBar(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Hero(
                tag: 'logo_text',
                child: Text(
                  "Habesha Dates",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Find your premium soulmate",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 60),

              // --- TOGGLE BETWEEN EMAIL & PHONE ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isEmailMode ? _buildEmailInput() : _buildPhoneInput(),
              ),

              const SizedBox(height: 32),
              _buildMainButton(),
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isEmailMode = !_isEmailMode),
                  child: Text(
                    _isEmailMode ? "Use Phone Number instead" : "Use Email instead",
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 48),
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 48),

              // --- SOCIAL LOGIN BUTTONS ---
              _buildSocialButton(
                label: "Continue with Gmail",
                icon: Icons.login, // Gmail icon placeholder
                onTap: _signInWithGmail,
              ),
              const SizedBox(height: 16),
              _buildSocialButton(
                label: "Continue with Telegram",
                icon: Icons.send,
                onTap: _signInWithTelegram,
              ),
              
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.white54),
                      children: [
                        TextSpan(
                          text: "Create Account",
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

  Widget _buildPhoneInput() {
    return Container(
      key: const ValueKey('phone_input'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Text(
            "+251",
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "911223344",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      key: const ValueKey('email_input'),
      children: [
        _buildTextField(_emailController, "Email", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField(_passwordController, "Password", Icons.lock_outline, obscureText: true),
      ],
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

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_isEmailMode ? _handleEmailAuth : _verifyPhoneNumber),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Text("Continue"),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.gold, size: 22),
        label: Text(label),
      ),
    );
  }
}
