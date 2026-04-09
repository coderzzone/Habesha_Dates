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
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized)
            SizedBox.expand(child: _buildCameraPreview())
          else
            const Center(child: CircularProgressIndicator(color: gold)),

          // TRANSPARENT OVERLAY WITH CUTOUT
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.8), BlendMode.srcOut),
              child: Stack(
                children: [
                   Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
                   Align(
                     alignment: Alignment.center,
                     child: Container(
                       width: size.width * 0.85,
                       height: (size.width * 0.85) * 0.63, // ID Card aspect ratio
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                     ),
                   ),
                ],
              ),
            ),
          ),

          // UI GUIDES
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("SCAN FRONT OF ID", style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18)),
                const Spacer(),
                const Text("Align your National ID / Fayda Card\nwithin the frame for automatic capture", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 30),
                _captureButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),

          Positioned(top: 50, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(builder: (context, constraints) {
      return Center(
        child: CameraPreview(_controller!),
      );
    });
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap: () async {
        if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
        
        setState(() => _isCapturing = true);
        
        try {
          final idImage = await _controller!.takePicture();
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (context) => SelfieVerificationScreen(idImagePath: idImage.path)));
        } catch (e) {
          debugPrint("Capture error: $e");
          if (mounted) setState(() => _isCapturing = false);
        }
      },
      child: Container(
        height: 85, width: 85, 
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
        child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      ),
    );
  }
}
