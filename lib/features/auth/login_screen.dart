import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Add this to pubspec.yaml

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
  bool _isEmailMode = false; // Toggle between Phone and Email
  String _verificationId = "";

  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceGrey = Color(0xFF1A1A1A);

  // --- 1. GOOGLE SIGN IN ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        _checkUserStatusAndNavigate();
      }
    } catch (e) {
      _showSnackBar("Google Sign-In failed.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. EMAIL & PASSWORD LOGIN/SIGNUP ---
  Future<void> _handleEmailAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // This attempt to sign in; if it fails because user doesn't exist, you could catch and create user
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _checkUserStatusAndNavigate();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Option: Auto-register if user doesn't exist
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _checkUserStatusAndNavigate();
      } else {
        _showSnackBar(e.message ?? "Authentication failed");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. PHONE AUTH LOGIC (Your existing logic) ---
  void _verifyPhoneNumber() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 9) {
      _showSnackBar("Please enter a valid phone number");
      return;
    }
    setState(() => _isLoading = true);
    String phoneNumber = "+251${_phoneController.text.trim()}";

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        _checkUserStatusAndNavigate();
      },
      verificationFailed: (e) {
        setState(() => _isLoading = false);
        _showSnackBar(e.message ?? "Failed");
      },
      codeSent: (id, token) {
        setState(() { _isLoading = false; _verificationId = id; });
        _showOtpBottomSheet();
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  void _showOtpBottomSheet() {
    final TextEditingController otpController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceGrey,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Verify Code", style: TextStyle(color: habeshaGold, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: InputDecoration(hintText: "000000", hintStyle: TextStyle(color: Colors.white24)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _verifyOtp(otpController.text),
              child: const Text("Verify"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _verifyOtp(String code) async {
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: code);
      await _auth.signInWithCredential(cred);
      if (mounted) { Navigator.pop(context); _checkUserStatusAndNavigate(); }
    } catch (e) { _showSnackBar("Invalid Code"); }
  }

  void _checkUserStatusAndNavigate() async {
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
  }

  void _showSnackBar(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text("Habesha Dates", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: habeshaGold)),
              const Text("Find your soulmate", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 40),

              // --- TOGGLE BETWEEN EMAIL & PHONE ---
              if (!_isEmailMode) ...[
                _buildPhoneInput(),
              ] else ...[
                _buildEmailInput(),
              ],

              const SizedBox(height: 20),
              _buildMainButton(),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isEmailMode = !_isEmailMode),
                  child: Text(_isEmailMode ? "Use Phone Number instead" : "Use Email instead", style: const TextStyle(color: habeshaGold)),
                ),
              ),

              const SizedBox(height: 30),
              Row(children: const [Expanded(child: Divider(color: Colors.white12)), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.white24))), Expanded(child: Divider(color: Colors.white12))]),
              const SizedBox(height: 30),

              // --- GOOGLE LOGIN BUTTON ---
              _buildSocialButton(
                label: "Continue with Google",
                icon: Icons.login, // You can replace with a Google Image asset
                onTap: _signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: surfaceGrey, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Text("+251", style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _phoneController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: "911223344", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none))),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      children: [
        TextField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Email", fillColor: surfaceGrey, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 10),
        TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Password", fillColor: surfaceGrey, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ],
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: habeshaGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : (_isEmailMode ? _handleEmailAuth : _verifyPhoneNumber),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("Continue", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}