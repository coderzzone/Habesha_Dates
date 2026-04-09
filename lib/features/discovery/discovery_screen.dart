import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import 'widgets/match_overlay.dart';
import 'ai_intent_match_screen.dart';
import '../../core/services/location_service.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/monetization_service.dart';
import '../monetization/paywall_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  final MonetizationService _monetizationService = MonetizationService();
  
  BannerAd? _bannerAd;
  bool _isPremium = false;
  int _swipeCount = 0;
  bool _limitReached = false;

  String? _myProfileUrl;
  String? _myGender;
  double? _myLat;
  double? _myLon;
  String? _lastSwipedUserId;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
    _updateLocation();
    _initMonetization();
  }

  void _initMonetization() async {
    // Listen for monetization updates (Premium status, Swipe count)
    _monetizationService.monetizationStream.listen((snapshot) {
      if (!mounted) return;
      if (!snapshot.exists) {
        setState(() {
          _isPremium = false;
          _swipeCount = 0;
        });
        if (_bannerAd == null) {
          _loadBannerAd();
        }
        return;
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final isPremium = data['isPremium'] ?? false;
      final swipeCount = data['swipeCount'] ?? 0;
      
      setState(() {
        _isPremium = isPremium;
        _swipeCount = swipeCount;
        // Check for 24h reset handled by canSwipe in handleswipe but we can check here too
      });

      if (!isPremium && _bannerAd == null) {
        _loadBannerAd();
      }
    });

    // Check if limit already reached
    final can = await _monetizationService.canSwipe();
    if (!can) {
      setState(() => _limitReached = true);
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'BannerAd failed to load: code=${error.code}, message=${error.message}, domain=${error.domain}',
          );
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  Future<void> _updateLocation() async {
    await LocationService.updateUserLocation();
  }

  Future<void> _fetchMyProfile() async {
    if (currentUserId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _myProfileUrl = data['profileImageUrl'];
          _myGender = data['gender'];
          _myLat = data['latitude'];
          _myLon = data['longitude'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _handleSwipeFromData(
    Map<String, dynamic> targetData,
    CardSwiperDirection direction,
  ) async {
    // Check if swipe is allowed
    final can = await _monetizationService.canSwipe();
    if (!can) {
      setState(() => _limitReached = true);
      _swiperController.undo();
      return;
    }

    final targetUid = targetData['id'];
    _lastSwipedUserId = targetUid;

    // Increment swipe count in background
    _monetizationService.incrementSwipe();

    if (direction == CardSwiperDirection.right) {
      await FirebaseFirestore.instance
          .collection('likes')
          .doc('${currentUserId}_$targetUid')
          .set({
            'from': currentUserId,
            'to': targetUid,
            'timestamp': FieldValue.serverTimestamp(),
          });

      final mutualDoc = await FirebaseFirestore.instance
          .collection('likes')
          .doc('${targetUid}_$currentUserId')
          .get();
      if (mutualDoc.exists && mounted) {
        List<String> ids = [currentUserId, targetUid]..sort();
        String chatRoomId = ids.join("_");
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .set({
              'users': ids,
              'lastMessage': "It's a match! Say hello.",
              'timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        await _notifyUser(
          toUserId: targetUid,
          type: 'match',
          data: {
            'chatId': chatRoomId,
            'message': "It's a match!",
          },
        );

        _triggerMatchOverlay(targetData, chatRoomId);
      }
    }
  }

  Future<void> _notifyUser({
    required String toUserId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (currentUserId.isEmpty || toUserId.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(toUserId).get();
      final userData = userDoc.data() ?? {};
      if (userData['notificationsEnabled'] == false) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'to': toUserId,
        'from': currentUserId,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Notification error: $e");
    }
  }

  void _handleUndo() async {
    if (_lastSwipedUserId != null) {
      _swiperController.undo();
      await FirebaseFirestore.instance
          .collection('likes')
          .doc('${currentUserId}_$_lastSwipedUserId')
          .delete();
      setState(() => _lastSwipedUserId = null);
    }
  }

  void _triggerMatchOverlay(Map<String, dynamic> targetUser, String chatId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (context, animation, secondaryAnimation) => MatchOverlay(
        myImageUrl: _myProfileUrl ?? "",
        partnerImageUrl: targetUser['profileImageUrl'] ?? "",
        partnerName: targetUser['name'] ?? "Someone",
        chatId: chatId,
      ),
    );
  }

  List<String> _targetGenderOptions() {
    final raw = (_myGender ?? '').trim();
    final lower = raw.toLowerCase();
    final targetLower = (lower == 'male') ? 'female' : 'male';
    final targetTitle = targetLower[0].toUpperCase() + targetLower.substring(1);
    return [targetLower, targetTitle];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopNav(),
              if (!_isPremium && _bannerAd != null)
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final bannerWidth = _bannerAd!.size.width.toDouble();
                    final bannerHeight = _bannerAd!.size.height.toDouble();

                    // Prevent horizontal overflow on narrow screens.
                    if (bannerWidth > screenWidth) return const SizedBox.shrink();

                    return SizedBox(
                      width: bannerWidth,
                      height: bannerHeight,
                      child: AdWidget(ad: _bannerAd!),
                    );
                  },
                ),
              Expanded(
                child: _myGender == null && FirebaseAuth.instance.currentUser != null
                    ? _buildProfileIncompleteState()
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where(
                              'gender',
                              whereIn: _targetGenderOptions(),
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(color: AppColors.gold),
                            );
                          }

                          final List<Map<String, dynamic>> docsWithDistance = [];
                          for (var d in snapshot.data!.docs) {
                            if (d.id == currentUserId) continue;
                            final data = d.data() as Map<String, dynamic>;
                            double? dist;
                            if (_myLat != null && _myLon != null && data['latitude'] != null && data['longitude'] != null) {
                              dist = LocationService.calculateDistance(_myLat!, _myLon!, data['latitude'], data['longitude']);
                            }
                            docsWithDistance.add({...data, 'id': d.id, 'distance': dist});
                          }

                          // Sort by distance (if available)
                          docsWithDistance.sort((a, b) {
                            if (a['distance'] == null) return 1;
                            if (b['distance'] == null) return -1;
                            return (a['distance'] as double).compareTo(b['distance'] as double);
                          });

                          final displayDocs = docsWithDistance.take(10).toList();

                          if (displayDocs.isEmpty) return _buildEmptyState();

                          return CardSwiper(
                      controller: _swiperController,
                      cardsCount: displayDocs.length,
                      numberOfCardsDisplayed: displayDocs.length > 1 ? 2 : 1,
                      backCardOffset: const Offset(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      onSwipe: (prev, current, direction) {
                        _handleSwipeFromData(displayDocs[prev], direction);
                        return true;
                      },
                      cardBuilder: (context, index, horizontal, vertical) {
                        final user = displayDocs[index];
                        return _buildUserCard(user, user['id']);
                      },
                    );
                  },
                ),
              ),
              _buildActionButtons(),
              if (!_isPremium) _buildSwipeCounter(),
              const SizedBox(height: 6),
            ],
          ),
          if (_limitReached) _buildLimitReachedOverlay(),
        ],
      ),
    );
  }

  Widget _buildSwipeCounter() {
    final remaining = MonetizationService.freeSwipeLimit - _swipeCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        "${remaining > 0 ? remaining : 0} swipes remaining today",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _buildLimitReachedOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on, color: AppColors.gold, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Daily Limit Reached",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "You've used all your 20 free swipes. Upgrade to Premium for unlimited swipes or watch an ad for 20 extra!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final upgraded = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen(reason: 'Unlock unlimited daily swipes.')),
                    );
                    if (upgraded == true) {
                      setState(() => _limitReached = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                  child: const Text('Upgrade to Premium', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: _watchAdForSwipes,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                  child: const Text('Watch Ad (+20 Swipes)', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => setState(() => _limitReached = false),
                child: const Text('Maybe Later', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _watchAdForSwipes() {
    AdService().showRewardedAd(
      onUserEarnedReward: (ad, reward) async {
        await _monetizationService.grantExtraSwipes(20);
        setState(() => _limitReached = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reward granted! +20 extra swipes.')));
        }
      },
      onAdFailedToLoad: () {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load ad. Try again later.')));
        }
      },
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.near_me_outlined, color: Colors.white, size: 28),
            onPressed: () => context.push('/nearby'),
          ),
          Text(
            "HABESHA DATES",
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          IconButton(
            onPressed: _openAiMatcher,
            icon: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 28),
          ),
        ],
      ),
    );
  }

  Future<void> _openAiMatcher() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AiIntentMatchScreen()));
  }

  Widget _buildUserCard(Map<String, dynamic> user, String id) {
    return GestureDetector(
      onTap: () => context.push('/profile_details/$id'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: user['profileImageUrl'] ?? "",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.white10,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${user['name'] ?? 'Anonymous'}, ${user['age'] ?? '??'}",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (user['isVerified'] == true) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: Colors.blue, size: 22),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.gold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${user['heritage'] ?? 'Habesha'} • ${user['religion'] ?? 'General'}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (user['distance'] != null) ...[
                                Icon(Icons.near_me, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "${user['distance']} km",
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
          _actionBtn(Icons.replay, AppColors.gold, _handleUndo, scale: 0.8),
          const SizedBox(width: 25),
          _actionBtn(
            Icons.close,
            Colors.red,
            () => _swiperController.swipe(CardSwiperDirection.left),
          ),
          const SizedBox(width: 25),
          _actionBtn(
            Icons.favorite,
            Colors.green,
            () => _swiperController.swipe(CardSwiperDirection.right),
            scale: 1.2,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    double scale = 1.0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(15 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: Colors.white10, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
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
          SizedBox(height: 24),
          Text(
            "No more profiles nearby!",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileIncompleteState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 80, color: AppColors.gold),
            const SizedBox(height: 24),
            const Text(
              "Almost there!",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Complete your profile to start seeing soulmates near you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/complete-profile'),
              child: const Text("Complete Profile"),
            ),
          ],
        ),
      ),
    );
  }
}

