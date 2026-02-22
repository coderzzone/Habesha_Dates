import 'package:flutter/material.dart';
// Add or fix this line specifically:
import 'id_capture_screen.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color habeshaEmerald = Color(0xFF064E3B);
  static const Color backgroundDark = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: habeshaGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VERIFICATION",
          style: TextStyle(
            color: habeshaGold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Get Verified",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              "Boost your profile trust and connect with authentic Ethiopian professionals using Fayda National ID.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 35),

            _buildFaydaCard(),

            const SizedBox(height: 40),

            // FIXED ICONS BELOW
            _verificationStep(
              icon: Icons.badge_outlined, // Replaced id_card
              title: "Upload ID Photo",
              subtitle: "Take a clear photo of your front-side Fayda ID card.",
              isLast: false,
            ),
            _verificationStep(
              icon: Icons.face_retouching_natural, // Replaced face_unlock
              title: "Face Scan",
              subtitle: "A quick video selfie to confirm your identity matches the ID.",
              isLast: false,
            ),
            _verificationStep(
              icon: Icons.verified,
              title: "Verification",
              subtitle: "Our system securely validates your data in seconds.",
              isLast: true,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: habeshaEmerald, size: 20),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Your data is encrypted and handled according to Ethiopian Data Protection regulations.",
                      style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildStartButton(context),
    );
  }

  Widget _buildFaydaCard() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [habeshaEmerald, Color(0xFF0A3A2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 15,
            top: 15,
            child: Icon(Icons.security, size: 70, color: Colors.white.withOpacity(0.1)), // Replaced shield_person
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FEDERAL DEMOCRATIC REPUBLIC\nOF ETHIOPIA",
                      style: TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(
                      "FAYDA ID",
                      style: TextStyle(color: habeshaGold, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      height: 65,
                      width: 55,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.person, color: Colors.white.withOpacity(0.2), size: 40),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 10, width: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(5))),
                        const SizedBox(height: 8),
                        Container(height: 10, width: 90, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(5))),
                      ],
                    )
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("0000 0000 0000", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
                    Text("NATIONAL ID CARD", style: TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _verificationStep({required IconData icon, required String title, required String subtitle, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: habeshaGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: habeshaGold.withOpacity(0.2)),
                ),
                child: Icon(icon, color: habeshaGold, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.white10, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      color: backgroundDark,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: habeshaEmerald,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IdCaptureScreen()), // Remove const
          );
        },
        child: const Text(
          "Start Verification",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}