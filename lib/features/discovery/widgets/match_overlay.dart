import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class MatchOverlay extends StatelessWidget {
  final String myImageUrl;
  final String partnerImageUrl;
  final String partnerName;
  final String chatId;

  const MatchOverlay({
    super.key,
    required this.myImageUrl,
    required this.partnerImageUrl,
    required this.partnerName,
    required this.chatId,
  });

  static const Color habeshaGold = Color(0xFFD4AF35);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // High opacity black to keep the focus on the match
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Header Text
            const Text(
              "It's a Match!",
              style: TextStyle(
                color: habeshaGold,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You and $partnerName liked each other.",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            
            const SizedBox(height: 60),

            // 2. The Overlapping Profile Circles
            _buildOverlappingImages(),

            const SizedBox(height: 80),

            // 3. Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the overlay
                      // Navigate to chat. Ensure your router supports this path.
                      context.push('/chat_room/$chatId?name=$partnerName');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: habeshaGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                      elevation: 5,
                    ),
                    child: const Text(
                      "SEND A MESSAGE",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38, width: 1.5),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                    ),
                    child: const Text(
                      "KEEP SWIPING",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlappingImages() {
    return SizedBox(
      height: 180,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Partner's Photo (Positioned Left)
          Positioned(
            left: 10,
            child: _profileCircle(partnerImageUrl, Icons.person),
          ),
          
          // Your Photo (Positioned Right)
          Positioned(
            right: 10,
            child: _profileCircle(myImageUrl, Icons.account_circle),
          ),
          
          // Centered Heart Icon to bridge the two photos
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.redAccent,
              size: 45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCircle(String url, IconData fallback) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: habeshaGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: (url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[900]),
                errorWidget: (context, url, error) => Icon(fallback, color: Colors.white24, size: 50),
              )
            : Container(
                color: Colors.grey[900],
                child: Icon(fallback, color: Colors.white24, size: 50),
              ),
      ),
    );
  }
}