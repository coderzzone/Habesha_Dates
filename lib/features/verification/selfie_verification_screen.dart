import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'verification_success_screen.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({required this.idImagePath, super.key});
  final String idImagePath;

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
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
          if (_isInitialized) SizedBox.expand(child: CameraPreview(_controller!))
          else const Center(child: CircularProgressIndicator(color: gold)),

          // CIRCULAR OVERLAY
          Center(
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 4)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("SELFIE VERIFICATION", style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                const Spacer(),
                const Text("Position your face in the circle", style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () async {
                    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

                    setState(() => _isCapturing = true);

                    try {
                      final selfieImage = await _controller!.takePicture();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VerificationSuccessScreen(
                            idImagePath: widget.idImagePath,
                            selfieImagePath: selfieImage.path,
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Capture error: $e");
                      if (mounted) setState(() => _isCapturing = false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 60),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(top: 50, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }
}
