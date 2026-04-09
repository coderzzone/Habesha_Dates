import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/image_service.dart';
import '../../core/services/monetization_service.dart';

class TelebirrPaymentScreen extends StatefulWidget {
  const TelebirrPaymentScreen({
    super.key,
    required this.amount,
  });

  final double amount;

  @override
  State<TelebirrPaymentScreen> createState() => _TelebirrPaymentScreenState();
}

class _TelebirrPaymentScreenState extends State<TelebirrPaymentScreen> {
  static const Color gold = Color(0xFFD4AF35);
  final MonetizationService _monetizationService = MonetizationService();
  File? _screenshot;
  bool _uploading = false;
  String _statusMessage = 'Pay via Telebirr, then send screenshot to Telegram @yafnad.';

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _screenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a screenshot first.')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _statusMessage = 'Uploading screenshot...';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = '${uid}_${const Uuid().v4()}.jpg';

      final url = await ImageService.uploadImage(
        _screenshot!,
        fileName,
        folder: 'payment_screenshots',
      );

      if (url == null) {
        throw Exception('Upload failed.');
      }

      if (url == 'size_limit_exceeded') {
        throw Exception('Screenshot too large (Limit: 1MB)');
      }

      setState(() => _statusMessage = 'Submitting request to admin...');

      await _monetizationService.submitTelebirrRequest(
        screenshotUrl: url,
        amount: widget.amount,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Success', style: TextStyle(color: gold)),
          content: const Text(
            'Your payment request has been submitted. We will verify via Telegram and activate premium shortly.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to previous screen
              },
              child: const Text('OK', style: TextStyle(color: gold)),
            ),
          ],
        ),
      );

    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Pay with Telebirr', style: TextStyle(color: gold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Follow these steps to complete your payment:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _step(1, 'Open your Telebirr app.'),
          _step(2, 'Send ${widget.amount.toStringAsFixed(0)} ETB to 0969526295.'),
          _step(3, 'Send the screenshot to Telegram @yafnad.'),
          _step(4, 'Upload the screenshot below for record.'),
          const SizedBox(height: 30),

          if (_screenshot != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  border: Border.all(color: gold.withValues(alpha: 0.5)),
                  image: DecorationImage(
                    image: FileImage(_screenshot!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 40),
                    onPressed: () => setState(() => _screenshot = null),
                  ),
                ),
              ),
            )
          else
            InkWell(
              onTap: _pickScreenshot,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, style: BorderStyle.none),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: gold, size: 40),
                    SizedBox(height: 10),
                    Text('Tap to Upload Screenshot', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _statusMessage.contains('Error') ? Colors.red : Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _uploading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _uploading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Submit Payment Notification',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
