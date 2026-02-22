import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  // --- BRAND COLORS ---
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceGrey = Color(0xFF1A1A1A);
  static const Color faydaGreen = Color(0xFF064D3B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            "< Back",
            style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold),
          ),
        ),
        title: const Text(
          "VERIFICATION",
          style: TextStyle(
            color: habeshaGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Get Verified",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Boost your profile trust and connect with authentic Ethiopian professionals using Fayda National ID.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 40),

            // ID CARD ILLUSTRATION
            _buildIDCardPreview(),

            const SizedBox(height: 40),

            // STEPS
            _buildStepRow(
              icon: Icons.badge_outlined,
              title: "Upload ID Photo",
              description: "Take a clear photo of your front-side Fayda ID card.",
            ),
            _buildStepConnector(),
            _buildStepRow(
              icon: Icons.face_retouching_natural,
              title: "Face Scan",
              description: "A quick video selfie to confirm your identity matches the ID.",
            ),
            _buildStepConnector(),
            _buildStepRow(
              icon: Icons.verified_user_outlined,
              title: "Verification",
              description: "Our system securely validates your data in seconds.",
              isLast: true,
            ),

            const SizedBox(height: 30),

            // DATA PROTECTION BOX
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF00C853), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Your data is encrypted and handled according to Ethiopian Data Protection regulations. We only use this to verify your age and authenticity.",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BUTTONS
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement verification logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: faydaGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Start Verification",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Maybe Later", style: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildIDCardPreview() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B2E), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Row(
              children: [
                const CircleAvatar(radius: 12, backgroundColor: Colors.yellow, child: Icon(Icons.star, size: 14, color: Colors.black)),
                const SizedBox(width: 10),
                Text(
                  "FEDERAL DEMOCRATIC REPUBLIC\nOF ETHIOPIA",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              height: 70,
              width: 55,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.person, color: Colors.white24, size: 40),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Text("FAYDA ID", style: TextStyle(color: habeshaGold.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({required IconData icon, required String title, required String description, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: habeshaGold.withOpacity(0.1),
            border: Border.all(color: habeshaGold.withOpacity(0.3)),
          ),
          child: Icon(icon, color: habeshaGold, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
      height: 25,
      width: 1,
      color: Colors.white10,
    );
  }
}