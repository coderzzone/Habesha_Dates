import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'selfie_verification_screen.dart'; 

class IdCaptureScreen extends StatefulWidget {
  const IdCaptureScreen({super.key});

  @override
  State<IdCaptureScreen> createState() => _IdCaptureScreenState();
}

class _IdCaptureScreenState extends State<IdCaptureScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use the back camera for ID scanning
    final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    
    _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
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
          // 1. Live Camera Preview
          if (_isInitialized)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: gold)),

          // 2. The Transparent Overlay with ID Cutout
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  // This is the "hole" for the ID card
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: (MediaQuery.of(context).size.width * 0.85) * 0.63, // ID Card aspect ratio
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. UI Elements (Guides and Button)
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "SCAN FRONT OF ID",
                    style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
                const Spacer(),
                const Text(
                  "Align your National ID / Fayda Card\nwithin the frame",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                _captureButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap: () async {
        if (_controller == null || !_controller!.value.isInitialized) return;
        
        try {
          final image = await _controller!.takePicture();
          // In a real app, you'd send image.path to your backend for OCR
          if (!mounted) return;
          
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelfieVerificationScreen()), // Remove 'const'
          );
        } catch (e) {
          print("Error taking picture: $e");
        }
      },
      child: Container(
        height: 80, width: 80,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}