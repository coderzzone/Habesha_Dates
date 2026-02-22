import 'package:flutter/material.dart';
import 'package:habesha_dates/features/verification/verification_screen.dart';


// --- GLOBAL CONSTANTS ---
const Color kGold = Color(0xFFD4AF35);
const Color kEmerald = Color(0xFF064E3B);
const Color kDarkBg = Color(0xFF121212);
const Color kCardDark = Color(0xFF1C1C1C);

class AiBreakdownScreen extends StatelessWidget {
  const AiBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Breakdown",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildMatchHeader(),
            const SizedBox(height: 30),
            _buildUserInfo(context),
            const SizedBox(height: 25),
            _buildAiInsightBox(),
            const SizedBox(height: 25),
            _buildChartTile(
              title: "Core Values",
              percent: "98% Synergy",
              color: kGold,
              icon: Icons.family_restroom,
              labels: ["Family Orientation", "Cultural Tradition"],
              values: [1.0, 0.95],
            ),
            const SizedBox(height: 15),
            _buildChartTile(
              title: "Lifestyle",
              percent: "88% Alignment",
              color: kEmerald,
              icon: Icons.festival,
              labels: ["Social Habits", "Travel & Leisure"],
              values: [0.82, 0.94],
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildMatchHeader() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleAvatar("https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e"),
              const SizedBox(width: 40),
              _circleAvatar("https://images.unsplash.com/photo-1506794778202-cad84cf45f1d"),
            ],
          ),
          Container(
            height: 75,
            width: 75,
            decoration: BoxDecoration(
              color: kDarkBg,
              shape: BoxShape.circle,
              border: Border.all(color: kGold, width: 2),
              boxShadow: [
                BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("94%", style: TextStyle(color: kGold, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("MATCH", style: TextStyle(color: Color(0x99D4AF35), fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _circleAvatar(String url) {
    return Container(
      height: 90,
      width: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 4),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Dawit M. 🎖️",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VerificationScreen()), // Remove const
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: Color(0xFF046307), size: 14),
                SizedBox(width: 6),
                Text(
                  "FAYDA VERIFIED PROFESSIONAL",
                  style: TextStyle(
                    color: Color(0xFF046307),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          "Addis Ababa • Senior Software Engineer",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAiInsightBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kGold.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: kGold, size: 16),
              SizedBox(width: 8),
              Text(
                "AI COMPATIBILITY INSIGHT",
                style: TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "\"Your shared focus on tech innovation in Addis and deep commitment to preserving Ethiopian family traditions makes you a highly compatible 'Modern Heritage' pair.\"",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartTile({
    required String title,
    required String percent,
    required Color color,
    required IconData icon,
    required List<String> labels,
    required List<double> values,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(percent, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < labels.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(labels[i], style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                Text("${(values[i] * 100).toInt()}%", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: values[i],
              color: color,
              backgroundColor: Colors.white.withOpacity(0.05),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 16),
          ]
        ],
      ),
    );
  }

  // --- FIXED THIS METHOD (The Error was here!) ---
  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: kDarkBg, // Color MUST be inside the BoxDecoration
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _btn(
              label: "Pass",
              bg: Colors.white.withOpacity(0.05),
              textCol: Colors.white70,
              icon: Icons.close,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: _btn(
              label: "Send Interest",
              bg: kGold,
              textCol: Colors.black,
              icon: Icons.favorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn({required String label, required Color bg, required Color textCol, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (bg == kGold) BoxShadow(color: kGold.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textCol, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}