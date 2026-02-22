import 'package:flutter/material.dart';

class GoldMembershipScreen extends StatefulWidget {
  const GoldMembershipScreen({super.key});

  @override
  State<GoldMembershipScreen> createState() => _GoldMembershipScreenState();
}

class _GoldMembershipScreenState extends State<GoldMembershipScreen> {
  // --- BRAND COLORS (Defined as constants for performance) ---
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color habeshaEmerald = Color(0xFF064E3B);
  static const Color backgroundDark = Color(0xFF171612);

  int selectedPlan = 1; // Default to 6 Months (Index 1)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP NAVIGATION BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Gold Membership",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Icon(Icons.help_outline, color: Colors.white),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 2. HERO GRADIENT CARD
                    _buildHeroCard(),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Premium Benefits",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),

                    // 3. BENEFITS LIST
                    _benefitTile(Icons.favorite, "Unlimited Likes"),
                    _benefitTile(Icons.visibility, "See Who Likes You"),
                    _benefitTile(Icons.public, "Addis & Diaspora Passport"),
                    _benefitTile(Icons.bolt, "Monthly Profile Boost"),

                    const SizedBox(height: 30),

                    // 4. PRICING SELECTION
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Your Plan",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    _buildPricingGrid(),
                  ],
                ),
              ),
            ),

            // 5. UPGRADE BUTTON (PAYWALL FOOTER)
            _buildFooterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [habeshaGold, habeshaEmerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: habeshaGold.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.workspace_premium, size: 200, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "PREMIUM STATUS",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "Elevate Your Connection",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Unlock the best of Habesha Dates",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _benefitTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: habeshaGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: habeshaGold, size: 18),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: habeshaGold, size: 20),
        ],
      ),
    );
  }

  Widget _buildPricingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          _pricingCard(0, "1 Month", "\$19.99", "/mo", ""),
          _pricingCard(1, "6 Months", "\$12.49", "/mo", "Save 38%"),
          _pricingCard(2, "12 Months", "\$8.33", "/mo", "Save 58%"),
        ],
      ),
    );
  }

  Widget _pricingCard(int index, String duration, String price, String sub, String save) {
    bool isSelected = selectedPlan == index;
    bool isBestValue = index == 1;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPlan = index),
        child: Container(
          height: 155,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isSelected ? habeshaEmerald.withOpacity(0.3) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? habeshaGold : Colors.white10, width: 2),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isBestValue)
                Positioned(
                  top: -12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: habeshaGold, borderRadius: BorderRadius.circular(20)),
                      child: const Text(
                        "BEST VALUE",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w900, // Fixed the .black error
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      duration,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    if (save.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        save,
                        style: const TextStyle(
                          color: habeshaGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: backgroundDark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: habeshaGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              onPressed: () {
                // Future Integration: Chapa / Telebirr Payment
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Processing Payment via Chapa..."),
                    backgroundColor: habeshaEmerald,
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Upgrade to Gold",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Recurring billing, cancel anytime.",
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}