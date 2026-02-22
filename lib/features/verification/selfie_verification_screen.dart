import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'verification_success_screen.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Use FRONT camera for selfie
    final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    
    _controller = CameraController(frontCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF35);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: gold)),

          // Circular Overlay for Selfie
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 4),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("SELFIE VERIFICATION", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                const Text("Position your face in the circle", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 30),
                IconButton(
                  icon: const Icon(Icons.camera, color: Colors.white, size: 70),
                  onPressed: () {
                    // In real app: capture and upload
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const VerificationSuccessScreen())
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}