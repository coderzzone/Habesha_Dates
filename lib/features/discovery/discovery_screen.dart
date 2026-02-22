import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/match_overlay.dart'; 

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color cardGrey = Color(0xFF1A1A1A);

  final CardSwiperController _swiperController = CardSwiperController();
  String? _myProfileUrl; 
  String? _lastSwipedUserId; 
  
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _fetchMyProfileImage();
  }

  Future<void> _fetchMyProfileImage() async {
    if (currentUserId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      if (doc.exists && mounted) {
        setState(() {
          _myProfileUrl = doc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _handleSwipe(DocumentSnapshot doc, CardSwiperDirection direction) async {
    final targetUid = doc.id;
    final targetData = doc.data() as Map<String, dynamic>;
    _lastSwipedUserId = targetUid;

    if (direction == CardSwiperDirection.right) {
      await FirebaseFirestore.instance.collection('likes').doc('${currentUserId}_$targetUid').set({
        'from': currentUserId,
        'to': targetUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final mutualDoc = await FirebaseFirestore.instance.collection('likes').doc('${targetUid}_$currentUserId').get();
      if (mutualDoc.exists && mounted) {
        List<String> ids = [currentUserId, targetUid]..sort();
        String chatRoomId = ids.join("_");
        await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
          'users': ids,
          'lastMessage': "It's a match! Say hello.",
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _triggerMatchOverlay(targetData, chatRoomId);
      }
    }
  }

  void _handleUndo() async {
    if (_lastSwipedUserId != null) {
      _swiperController.undo();
      await FirebaseFirestore.instance.collection('likes').doc('${currentUserId}_$_lastSwipedUserId').delete();
      setState(() => _lastSwipedUserId = null);
    }
  }

  void _triggerMatchOverlay(Map<String, dynamic> targetUser, String chatId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      pageBuilder: (context, _, __) => MatchOverlay(
        myImageUrl: _myProfileUrl ?? "",
        partnerImageUrl: targetUser['profileImageUrl'] ?? "",
        partnerName: targetUser['name'] ?? "Someone",
        chatId: chatId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed the root Material/Scaffold to let the AppRouter's Scaffold handle the background
    return SafeArea(
      child: Column(
        children: [
          _buildTopNav(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: habeshaGold));
                
                final docs = snapshot.data!.docs.where((d) => d.id != currentUserId).toList();
                if (docs.isEmpty) return _buildEmptyState();

                return CardSwiper(
                  controller: _swiperController,
                  cardsCount: docs.length,
                  numberOfCardsDisplayed: docs.length > 1 ? 2 : 1,
                  backCardOffset: const Offset(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  onSwipe: (prev, current, direction) {
                    _handleSwipe(docs[prev], direction);
                    return true;
                  },
                  cardBuilder: (context, index, horizontal, vertical) {
                    final user = docs[index].data() as Map<String, dynamic>;
                    return _buildUserCard(user, docs[index].id);
                  },
                );
              },
            ),
          ),
          _buildActionButtons(),
          // Padding to ensure we don't overlap the BottomNavigationBar
          const SizedBox(height: 10), 
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.auto_awesome, color: habeshaGold, size: 28),
          const Text(
            "HABESHA DATES", 
            style: TextStyle(
              color: habeshaGold, 
              fontFamily: 'Ethiopic', // If you have a custom font
              fontWeight: FontWeight.bold, 
              letterSpacing: 2, 
              fontSize: 18, 
              decoration: TextDecoration.none
            )
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white, size: 28), 
            // CHANGED: Use .go instead of .push to stay within the Shell
            onPressed: () => context.go('/settings') 
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String id) {
    return GestureDetector(
      onTap: () => context.push('/profile_details/$id'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: const BoxDecoration(color: cardGrey),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: user['profileImageUrl'] ?? "",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: cardGrey, 
                    child: const Center(child: CircularProgressIndicator(color: habeshaGold))
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 100, color: Colors.white10),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${user['name'] ?? 'Anonymous'}, ${user['age'] ?? '??'}",
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 28, 
                        fontWeight: FontWeight.bold, 
                        decoration: TextDecoration.none
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: habeshaGold, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          "${user['heritage'] ?? 'Habesha'} • ${user['religion'] ?? 'General'}",
                          style: const TextStyle(
                            color: habeshaGold, 
                            fontSize: 16, 
                            fontWeight: FontWeight.w600, 
                            decoration: TextDecoration.none
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionBtn(Icons.replay, habeshaGold, _handleUndo, scale: 0.8),
          const SizedBox(width: 25),
          _actionBtn(Icons.close, Colors.red, () => _swiperController.swipe(CardSwiperDirection.left)),
          const SizedBox(width: 25),
          _actionBtn(Icons.favorite, Colors.green, () => _swiperController.swipe(CardSwiperDirection.right), scale: 1.2),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap, {double scale = 1.0}) {
    return Material( // Added Material here to handle the InkWell splash properly
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(15 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: cardGrey, 
            border: Border.all(color: Colors.white10, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), 
                blurRadius: 10, 
                spreadRadius: 2
              )
            ],
          ),
          child: Icon(icon, color: color, size: 30 * scale),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.white24),
          SizedBox(height: 20),
          Text(
            "No more profiles nearby!", 
            style: TextStyle(color: Colors.white70, fontSize: 18, decoration: TextDecoration.none)
          ),
        ],
      ),
    );
  }
}