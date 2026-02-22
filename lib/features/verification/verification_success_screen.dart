import 'package:flutter/material.dart';

class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF35);
    const emerald = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BIG VERIFIED ICON
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withOpacity(0.1),
                    ),
                  ),
                  const Icon(Icons.verified, size: 100, color: gold),
                ],
              ),
              const SizedBox(height: 40),
              const Text("Verification Complete!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text(
                "Your profile now stands out with the official Fayda trust mark.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 50),

              // BACK TO DISCOVERY BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emerald,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  // Go back to the main Swipe screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Go to Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}