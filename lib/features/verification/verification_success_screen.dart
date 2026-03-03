import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/verification_service.dart';

class VerificationSuccessScreen extends StatefulWidget {
  const VerificationSuccessScreen({
    required this.idImagePath,
    required this.selfieImagePath,
    super.key,
  });

  final String idImagePath;
  final String selfieImagePath;

  @override
  State<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  static const Color gold = Color(0xFFD4AF35);
  static const Color emerald = Color(0xFF064E3B);

  final TextEditingController _idNumberController = TextEditingController();
  final VerificationService _verificationService = VerificationService();

  bool _isLoading = false;
  String? _errorText;
  bool _isVerified = false;

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorText = 'Please log in again to continue.');
      return;
    }

    final nationalId = _idNumberController.text.trim();
    if (!_verificationService.isValidNationalId(nationalId)) {
      setState(() => _errorText = 'Enter a valid Fayda/National ID number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _verificationService.verifyAndPersist(
        uid: user.uid,
        nationalIdNumber: nationalId,
        idImageFile: File(widget.idImagePath),
        selfieImageFile: File(widget.selfieImagePath),
      );

      if (!mounted) return;
      setState(() => _isVerified = true);
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'id_already_registered') {
        setState(() {
          _errorText =
              'This ID is already linked to another account. Contact support if this is a mistake.';
        });
      } else {
        setState(() => _errorText = 'Verification failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Verification failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isVerified
              ? _buildSuccess(context)
              : _buildSubmitCard(context),
        ),
      ),
    );
  }

  Widget _buildSubmitCard(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 90, color: gold),
        const SizedBox(height: 20),
        const Text(
          'Final Step',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter your Fayda/National ID number to complete verification.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _idNumberController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'National ID Number',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gold),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: emerald,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Complete Verification',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Back', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gold.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.verified, size: 100, color: gold),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verification Complete!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your account is now verified and your ID signature is locked to this account.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/profile_view'),
            style: ElevatedButton.styleFrom(
              backgroundColor: emerald,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Go to Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
